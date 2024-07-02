# Epics::Box

[![Build Status](https://travis-ci.com/railslove/ebicsbox.svg?token=EhFJyZWe1sxdBDmF2bzC&branch=fix-gready-route)](https://travis-ci.com/railslove/ebicsbox)

Epics Box is a selfcontained solution to handle SEPA credit/debits and bank statement
reconcilliation.

It offers a HTTP interface and can be integrated with different message queueing systems

## Kickstart
In order to kickstart the project you can choose what fits you preferences.

### Locally
* have a **postgres** server running
* have a **redis** server running
* install all ruby **dependencies**: `bundle install`
* for dotenv-rails copy `.env.example` to `.env` and update values if needed
* to prepare **development database**: `createdb ebicsbox`

### Docker
* Spin up the docker-compose project with the web config: `docker-compose -f docker-compose.with_db.yml up`


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

If you want to use a custom postgres instance provide the database connection strings:

- `DATABASE_URL`
- `TEST_DATABASE_URL`

see config/configuration.rb

SSL forcing can be disabled by setting

- `DISABLE_SSL_FORCE`

You can enable webhook payload encryption by setting 

- `WEBHOOK_ENCRYPTION_KEY`

It expects to be a base64-encoded RSA public key in PEM format (see below).


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

### Generate a Webhook encryption key


If OpenSSL is not installed, please refer to the OpenSSL documentation for installation instructions specific to your operating system.

#### Step 1: Generate the Private-Public Keypair

To generate the private-public keypair, follow these steps:

1. Open your terminal or command prompt.

2. Run the following command to generate a private key file named `private_key.pem`: 
```bash
  openssl genpkey -algorithm RSA -out private_key.pem
``` 

3. You will be prompted to set a passphrase for the private key. Choose a strong passphrase and remember it for future use.

4. Run the following command to generate the corresponding public key file named `public_key.pem`:

```bash
  openssl rsa -pubout -in private_key.pem -out public_key.pem
``` 

5. Remember to keep the private key (`private_key.pem`) secure and do not share it with anyone.

#### Step 2: Encode the Public Key in Base64

To encode the public key in Base64, follow these steps:

1. Use the following command to encode the public key in Base64:

```bash
openssl base64 -in public_key.pem -out public_key_base64.txt
```

2. The public key is now encoded in Base64 and saved as `public_key_base64.txt`. The file contains the Base64-encoded public key.

Congratulations! You have successfully generated a private-public keypair, converted the public key to a `.pem` file, and encoded it in Base64. You can now use it for `WEBHOOK_ENCRYPTION_KEY` (see above).

## Usage

see [docs.ebicsbox.apiary.io](http://docs.ebicsbox.apiary.io)

### Tests

We are using RSpec to test this project. In order to execute all specs once, run `bundle exec rspec`.

To migrate your test database run the following command:

```bash
  $ `ENVIRONMENT`=test bundle exec bin/migrate
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

## Contributing

1. Fork it ( https://github.com/[my-github-username]/epics-http/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
