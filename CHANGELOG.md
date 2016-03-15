# Changelog

# 0.5.0

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

# 0.4.0

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
