# Changelog

## 0.7

We ditched jruby in favor of ruby. This is great news!
API Changes for V2:
* Events are now availabe for V2
* Credits higher than 120.000€ are now allowed


## 0.6.1

We're now using supervisord to spawn processes on startup

## 0.6.0

Integrated CAMT.053 parsing

* It is now possible to switch between mt940 / camt53 for each account
* Statements are fetched more frequently w/ camt53

_Important_: Switching to C53 requires to remove old mt940 statements for the according account.
Checksum calculation will not match C53 and mt940 statements!

## 0.5.4

Bugfix for running latest migrations without complications

## 0.5.3

Minor features and optimizations regarding statements

* Expose a unique statement id so clients can use it to prevent duplicates while importing
* Optimize checksum calculation for statements, so similar looking entries are imported correctly

## 0.5.2

Bugfix release

* Handle exceptions when creating multiple bank statements at once
* Add a migration to clean up a previous migration fuckup and add webhook tokens to organizations

## 0.5.1

Bugfix release

* Migrations run properly on setup
* Updated documentation
* Updated docker compose file

## 0.5.0

This release is a major rewrite of the way we handle incoming data on statements and transactions.
We now embrace the concept of account statements which include multiple transactions. It allows us
to store raw MT940 data economically. Moreover, we can easily rebuild statement data in case of
issues we are having with MT940 parsing.

* Store all incoming bank statements in a separate table
* Link account statements to imported bank statements
* Rebuild statement data from bank statements, as we had an issue with MT940 parsing
* Update to latest CMXL code to resolve issues with MT940 parsing.

In addition to that, this release also includes a few additions in preparation of our upcoming
distributed signature feature:

* Users can add their subscriber id (only one) for each account via non-management API endpoint
* Expose more data on accounts (include subscriber for current user)

## 0.4.0

This release focuses on how to authenticate. There is an accompanying project to perform user
on-boarding and managing core data. By switching to OAuth we can provide a nice UI without having
to include it in the box.

* Drop support for organization management tokens
* Add user admin flag to limit access to management features

## 0.3.0

* Expose events via https://box/events (including information about webhook deliveries)
* Expose raw MT940 in statements when requested via header or query parameter
* Harden security around webhook payload verification
* Fix issues with interactive documentation using http instead of https
* Fix minor mistakes in documentation

## 0.2.0

This is the first release where we will apply the semantic versioning scheme. All changes listed
below have been added in the last few releases. Expect that we move forward in a more organized way.

* Switch to JRuby 9.0.5.0
* Proper support of OAuth Bearer tokens
* Track account balance
* Manual triggering of statement retrieval
* HTTP authentication for webhooks
* Fallback to non-T subscribers if none exists
* Improved onboarding API (INI letter, access tokens, etc.)
* Additions to documentation
* Automatic host detection for documentation
* Minimal fake backend for triggering statements (immediate dev feedback)
* Proper support for Deutsche Bank's MT940 file format
* Proper support for Deutsche Bank's sub-accounts format
* Improved security by self-managed docker base images
* Reduced JVM memory footprint
* Additional logging for queued jobs
* Everything else ;)
