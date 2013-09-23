require 'yaml'
require 'mail'

DAEMON_ROOT = File.dirname(File.dirname(__FILE__))

options = YAML.load_file(DAEMON_ROOT + "/config/smtp.yml")

# {
#   :address              => "smtp.gmail.com",
#   :port                 => 587,
#   :domain               => 'smtp.gmail.com',
#   :user_name            => 'fenix.mercury@gmail.com',
#   :password             => 'xwynmntnkeuuxnwa',
#   :authentication       => 'plain',
#   :enable_starttls_auto => true
# }

Mail.defaults do
  delivery_method :smtp, options
end

# Change this file to be a wrapper around your daemon code.

# Do your post daemonization configuration here
# At minimum you need just the first line (without the block), or a lot
# of strange things might start happening...
DaemonKit::Application.running! do |config|
  # Trap signals with blocks or procs
  # config.trap( 'INT' ) do
  #   # do something clever
  # end
  # config.trap( 'TERM', Proc.new { puts 'Going down' } )
end

DaemonKit.logger.info '"I am the watcher on the wall"'

wards = Dir[DAEMON_ROOT + "/config/wards/**/*.yml"].map do |file|
  Mash.new YAML.load_file(file)
end

DaemonKit.logger.info "Loaded #{wards.count} wards…"

loop do

  wards.each do |ward|
    DaemonKit.logger.info "Watching #{ward.name}…"
    conn = Faraday.new url: ward.url

    ward.checks.each do |check|
      DaemonKit.logger.info "Checking if #{check.check_if}…"

      response = conn.get do |req|
        req.url check.uri
        req.headers[:user_agent] = 'Sentry'
      end

      notify = true

      check.conditions.each_index do |index|
        condition = check.conditions[index]

        if condition.request_status?
          if response.status != condition.request_status
            DaemonKit.logger.info "Condition #{index+1} not met: expected request_status of #{condition.request_status} but got #{response.status}"
            notify = false
            break
          end
        end

        if condition.body_does_not_contain_string?
          if response.body =~ /#{condition.body_does_not_contain_string}/i
            DaemonKit.logger.info "Condition #{index+1} not met: expected response to not contain '#{condition.body_does_not_contain_string}' but did"
            notify = false
            break
          end
        end

        if condition.body_contains_string?
          unless response.body =~ /#{condition.body_contains_string}/i
            DaemonKit.logger.info "Condition #{index+1} not met: expected response to contain '#{condition.body_does_not_contain_string}' but did not"
            notify = false
            break
          end
        end
      end

      if notify && check.notifications?
        DaemonKit.logger.info "Condtions met, sending notifications…"

        begin
          DaemonKit.logger.info "Taking screenshot of web page…"
          screenshot = IMGKit.new(response.body, quality: 50)
        rescue Exception => e
          DaemonKit.logger.info "Failed to take screenshot of web page <#{e.message}>"
          screenshot = nil
        end

        check.notifications.each do |notification|
          mail = Mail.new do
            to notification.to
            from options[:user_name]
            subject "Sentry alert: #{notification.subject}"
            body "You asked Sentry to alert you when #{check.check_if}. That time is now!\n\n#{ward.url}#{check.uri}"
            add_file :filename => 'screenshot.jpg', :content => screenshot.to_img(:jpg) if screenshot
          end

          DaemonKit.logger.info mail.to_s

          mail.deliver
        end
      end
    end
  end

  sleep 600 + rand(30)
end
