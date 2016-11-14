[![Gem Version](https://badge.fury.io/rb/xymonclient.svg)](https://badge.fury.io/rb/xymonclient)
[![Build Status](https://travis-ci.org/dchauviere/ruby-xymonclient.svg?branch=master)](https://travis-ci.org/dchauviere/ruby-xymonclient)
[![Code Climate](https://codeclimate.com/github/dchauviere/ruby-xymonclient/badges/gpa.svg)](https://codeclimate.com/github/dchauviere/ruby-xymonclient)
<a href="https://codeclimate.com/github/dchauviere/ruby-xymonclient/coverage"><img src="https://codeclimate.com/github/dchauviere/ruby-xymonclient/badges/coverage.svg" /></a>
# XymonClient

XymonClient is a ruby library for interacting with Xymon

Features:
 * Send status
 * Ack
 * Enable/Disable
 * Helper Class 'Service' for building sensors easily

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'xymonclient'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install xymonclient

## Usage

### Basic usage
```ruby
require 'xymonclient'

client = XymonClient::Client.new(['localhost:1984'])
client.status('myhost', 'service1', 'green', 'additional data')

```

### Service wrapper
```ruby
require 'xymonclient/service'

service = XymonClient::Service.new(['localhost:1984'],
  'name' => 'service1',
  'host' => 'myhost',
  'header' => 'A sample header',
  'footer' => 'A sample footer',
  'items' => {
    'ITEM1' => {
      'label' => 'Gauge Item 1',
      'type' => 'gauge',
      'threshold' => {
        'order' => '<',
        'critical' => 5,
        'warning' => 10,
        'nan_status' => 'red'
      }
    },
    'ITEM2' => {
      'label' => 'String Item 2',
      'type' => 'string',
      'threshold' => {
        'inclusive' => false,
        'critical' => ['all is Ok !']
      }
    }
  }
)
service.update_item('ITEM1', 3)
service.update_item('ITEM2', 'all is Ok !')
service.status
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dchauviere/xymonclient.
