# Epics::Box

[![Build Status](https://magnum.travis-ci.com/railslove/epics-box.svg?token=AM3M96RpNyP5z4TXrjkp&branch=master)](https://magnum.travis-ci.com/railslove/epics-box)

Epics Box is a selfcontained solution to handle SEPA credit/debits and bank statement
reconcilliation.

It offers a HTTP interface and can be integrated with different message queueing systems

## Getting started

    $ createdb ebicsbox
    $ sequel -m migrations postgres://localhost/ebicsbox

## Prerequistes

* ruby (jruby / ruby 2.2.x)
* beanstalkd
* postgres
* webpack (npm install webpack -g)

## Development

Run it: 

    $ forman start -f Procfile.dev


## Installation

Run it:

    $ foreman start

## Configuration

Set the following environment variables: 

* DATABASE_URL
* BEANSTALKD_URL
* PASSPHRASE
* SECRET_TOKEN

you can store these in a local .env file for development.

Is done via environment variables. You can utilize a `.env` file while
developing locally. Please revise `.env.example` for a overview
of needed parameters.

### Generate a secret token

In order to ensure that webhooks are originating from your EbicsBox and have not been modified, we
sign each webhook with a predefined secret. Each box should have a unique secret key. In order to
generate one, you can use the following command:

```bash
  ruby -rsecurerandom -e 'puts SecureRandom.hex(20)'
```

## Usage

see [docs.ebicsbox.apiary.io](http://docs.ebicsbox.apiary.io)

### Tests

We are using RSpec to test this project. In order to execute all specs once, run ```bundle exec rspec```.
If you are actively developing, you can execute specs automatically by running guard with ```bundle exec guard```.


## Contributing

1. Fork it ( https://github.com/[my-github-username]/epics-http/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
