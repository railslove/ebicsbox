# Epics::Box

[![Build Status](https://magnum.travis-ci.com/railslove/epics-box.svg?token=AM3M96RpNyP5z4TXrjkp&branch=master)](https://magnum.travis-ci.com/railslove/epics-box)

Epics Box is a selfcontained solution to handle SEPA credit/debits and bank statement
reconcilliation.

It offers a HTTP interface and can be integrated with different message queueing systems

## Getting started

    $ createdb ebicsbox
    $ sequel -m migrations postgres://localhost/ebicsbox

## Prerequistes

* beanstalkd
* postgres

## Installation

Install it:

    $ gem install epics-box

Run it:

    $ foreman start

In development, run it with

    $ foreman start -f Procfile.dev

## Configuration

## Usage
### HTTP

```ruby
  POST https://ebics.box/debits
  {
    "callback": "https://"
    "document": "< a base64 encoded representation of a pain008 document >"
    "creditor_identifier": ""
    "transactions": [
      {
        "name": "Peter Pan",
        "bic": "COLSDE33XXX",
        "iban": "DE51370501981929807319",
        "amount": "100.00",
        "reference": "",
        "remittance_information": "",
        "mandate_id": "number",
        "mandate_date_of_signature": "",
        "local_instrument": "CORE",
        "sequence_type": "FRST",
        "requested_date": ""
      }
    ]
    "order_type": "CDD"
  }
```


```ruby
  POST https://ebics.box/credits
  {
    "callback": "https://"
    "document": "< a base64 encoded representation of a pain001 document >"
    "transactions": [
      {
        "name": "Peter Pan",
        "bic": "COLSDE33XXX",
        "iban": "DE51370501981929807319",
        "amount": "100.00",
        "reference": "",
        "remittance_information": ""
      }
    ]
  }
```
### Message Queue


### Tests

We are using RSpec to test this project. In order to execute all specs once, run ```bundle exec rspec```.
If you are actively developing, you can execute specs automatically by running guard with ```bundle exec guard```.


## Contributing

1. Fork it ( https://github.com/[my-github-username]/epics-http/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
