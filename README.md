# Epics::Box

[![Build Status](https://travis-ci.com/railslove/ebicsbox.svg?token=EhFJyZWe1sxdBDmF2bzC&branch=fix-gready-route)](https://travis-ci.com/railslove/ebicsbox)

Epics Box is a selfcontained solution to handle SEPA credit/debits and bank statement
reconcilliation.

It offers a HTTP interface and can be integrated with different message queueing systems

## Prerequisites

- ruby (ruby 2.5.x)
- redis
- postgres

## Getting started

    $ createdb ebicsbox
    $ bundle exec bin/migrate

## Development

Run it:

    $ foreman start

## Installation

Run it:

    $ foreman start

## Configuration

Set the following environment variables:

- `PASSPHRASE`
- `AUTH_SERVICE`
  - `static` - _auth via access_token_
  - `oauth` - _oauth, also requires server and jwt details, see .env.example_

If you want the box to be available via a custom (sub-)domain, also provide these

- `VIRTUAL_HOST`
- `LETSENCRYPT_HOST`
- `LETSENCRYPT_EMAIL`

If you want to use a custom Redis instance provide the Redis conection strings:

- `REDIS_URL` (redis://* for plain or rediss://* for ssl)
- `REDIS_PASSWORD` (in case authentication is required)

If you want to use a custom postgres instance provide the database connection strings:

- `DATABASE_URL`
- `TEST_DATABASE_URL`

see config/configuration.rb

SSL forcing can be disabled by setting

- `DISABLE_SSL_FORCE`

you can store these in a local .env file for development.

It's done via environment variables. You can utilize a `.env` file while
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
  $ `ENVIRONMENT`=test bundle exec bin/migrat
```

### Error Tracking

The ebicsbox enables sentry or rollbar as the error tracking software of choice.

_using sentry_ \
Define `SENTRY_DSN` via an environment variable to enable error tracking via sentry

_using rollbar_ \
Define `ROLLBAR_ACCESS_TOKEN` via an environment variable to enable error tracking via rollbar

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
