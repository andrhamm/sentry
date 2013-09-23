sentry
======
`sentry` will watch any web request for you and notify you when the desired condition is met.

## Usage
To run the bot, simply run

`./bin/sentry`

Or

`./bin/sentry start`

## Configuration

### Configure email settings
Sentry currently only supports SMTP email sending. Rename `config/sample_smtp.yml` to `config/smtp.yml` and update with your email connection settings.

## Create your "wards"
Tell Sentry what to look for, on which sites, by creating your own custom "wards" in the `config/wards` directory. A ward is a simple YAML config that specifies which URLs to monitor, and the conditions on which you want to be alerted. A sample ward has been provided. Support for additional conditions will be added in future versions.

## Installation
Install dependencies, then simply run `bundle install`

## Dependencies

Sentry will attach a screenshot of the web page when notifying you with an alert. [IMGKit](https://github.com/csquared/IMGKit) is required to support this feature.

`gem install imgkit`

`rbenv rehash` (may not be necessary)

`sudo imgkit --install-wkhtmltoimage`

## TODO
- Implement [dotenv](https://github.com/bkeepers/dotenv) in place of YAML configs
- Make more Ruby-y
- Add more support for conditions
- Code organization