# Epics::Box

[![Build Status](https://travis-ci.com/railslove/ebicsbox.svg?token=EhFJyZWe1sxdBDmF2bzC&branch=fix-gready-route)](https://travis-ci.com/railslove/ebicsbox)

Epics Box is a selfcontained solution to handle SEPA credit/debits and bank statement
reconcilliation.

It offers a HTTP interface and can be integrated with different message queueing systems

## Prerequisites

- ruby (jruby / ruby 2.5.x)
- redis
- postgres

## Getting started

    $ createdb ebicsbox
    $ bundle exec bin/migrate

## Development

Run it:

    $ foreman start

If this is too noisy, you can prefix the command with `RUBYOPT="-W0"` which removes warnings
raised by jruby about uninitialized variables.

Furthermore, we recommend using `JRUBY_OPTS="$JRUBY_OPTS --dev"` which speeds up jruby quite a
bit. Check https://github.com/jruby/jruby/wiki/Improving-startup-time for more infomation about it.

## Installation

Run it:

    $ foreman start

## Configuration

Set the following environment variables:

- PASSPHRASE=
- AUTH_SERVICE=
  - "static":
  - [default (oauth)]:
- VIRTUAL_HOST=
- LETSENCRYPT_HOST=
- LETSENCRYPT_EMAIL=

If you want to use a custom postgres instance provide the database connection strings:

- DATABASE_URL=
- TEST_DATABASE_URL=

see config/configuration.rb

you can store these in a local .env file for development.

Is done via environment variables. You can utilize a `.env` file while
developing locally. Please revise `.env.example` for a overview
of needed parameters.

### Generate a secret token

In order to ensure that webhooks are originating from your EbicsBox and have not been modified, we
sign each webhook with a predefined secret. Each box should have a unique secret key. In order to
generate one, you can use the following command:

```bash
  ruby -rsecurerandom -e 'puts SecureRandom.hex(32)'
```

## Usage

see [docs.ebicsbox.apiary.io](http://docs.ebicsbox.apiary.io)

### Tests

We are using RSpec to test this project. In order to execute all specs once, run `bundle exec rspec`.

To migrate your test database run the following command:

```bash
  $ ENVIRONMENT=test bundle exec bin/migrate
```

### Documentation

Our goal is to provide an always up-to-date documentation from within the app.

Documentation is available at http://YOUR-HOST/docs

> v1 docs are not maintained anymore and are just available as static swagger file

## Contributing

1. Fork it ( https://github.com/[my-github-username]/epics-http/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
