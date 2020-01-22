# Changelog

## 1.3.20- 13.22

- `[ENHANCEMENT]` Use transaction-id to calculate checksum if available
- `[HOUSEKEEPING]` Migration will recalculate checksums for statements
- `[BUGFIX]` Migration to 1.3.20 could fail when statement data in invalid due to previous fixed issues

## 1.3.19

- `[ENHANCEMENT]` Adds transactions detail endpoint to v2 api

## 1.3.16 - 1.3.18

- `[ENHANCEMENT]` Improves dublication checks for statements to handle edge-cases

## 1.3.15

- `[ENHANCEMENT]` Enhances the statement SHA calculation further to drop whitespaces from references. camt53 / mt940 seem to handle them differently

## 1.3.14

- `[ENHANCEMENT]` Enhances Statement SHA calculation to prevent false positive duplicate checks

## 1.3.13

- `[HOUSEKEEPING]` Updates CMXL-Gem to parse more weird bank responses

## 1.3.12

- `[ENHANCEMENT]` Improves logging when failing to import statement due to unknown subaccount

## 1.3.11

- `[BUGFIX]` Changing interval to fetch upcoming statements now uses correct class

## 1.3.10

- `[ENHANCEMENT]` Queues VMK-jobs separatly so a single failure does not interfer with other imports
- `[HOUSEKEEPING]` Updates CMXL-Gem to fix some weird bank responses

## 1.3.9

- `[FEATURE]` Create organizations through v2 API
- `[ENHANCEMENT]` Ensure contradicting params for credit_transfers are handled (i.e. urgent with foreign currency)
- `[HOUSEKEEPING]` Aligns code with current rubocop guidelines
- `[HOUSEKEEPING]` Improves v2 management ebics_users endpoint-implementation

## 1.3.8

- `[FEATURE]` Now supports rollbar, README updated
- `[ENHANCEMENT]` Exception Trackers now work in dev mode too

## 1.3.7

- `[ENHANCEMENT]` Adds ability to delete users via v2 management
- `[HOUSEKEEPING]` Improves docker setup
- `[HOUSEKEEPING]` Adds documentation for docker setup

## 1.3.6

- `[ENHANCEMENT]` Fetch Statements Job now runs parallelized for multiple accounts
- `[ENHANCEMENT]` Scheduled Jobs won't get retried anymore
- `[HOUSEKEEPING]` Adds advanced metrics for Heroku
- `[HOUSEKEEPING]` Reduces log output in INFO mode
- `[HOUSEKEEPING]` Reduces default timerange to fetch statements for to 7 days (was 30)
- `[HOUSEKEEPING]` Reduces default timerange to fetch upcoming statements for to 30 days (was 180)
- `[HOUSEKEEPING]` Adds advanced metrics support for heroku

## 1.3.5

- `[BUGFIX]` Don't remove Rakefile from Dockerfile so rake tasks can be executed correctly

## 1.3.4

- `[ENHANCEMENT]` EbicsUser users partner to determine all accounts belong to the same bank

## 1.3.3

- `[BUGFIX]` Fake-Mode now creates direct debits qas debits

## 1.3.2

- `[ENHANCEMENT]` Fake-Mode now handles information for direct debits properly
- `[HOUSEKEEPING]` Tagging dockerimages works now with semaphore

## 1.3.1

- `[FEATURE]` Fake-Mode now generated proper direct debit statements

## 1.3.0

- `[FEATURE]` supports MT942 / VMK<br>
  set `UPCOMING_STATEMENTS_INTERVAL` to define fetching interval (minutes,_default: 60_)<br>
  upcoming transactions will appear as statements in the `/statements` endpoint
- `[FEATURE]` retry failed webhooks (see API-Docs at `/docs` for more details)
- `[ENHANCEMENT]` multiple accounts per ebics_user

## 1.2.1

- `[BUGFIX]` fixes migrations missing statements public-id default value

## 1.2.0

- `[HOUSEKEEPING]` removes clockwork in favor of sidekiq-scheduler
- `[FEATURE]` added env-variable (`ACTIVATE_EBICS_USER_INTERVAL`) to defined interval (minutes) of activation jobs (_default: 60_)
- `[ENHANCEMENT]` account activation is now a recurring job to prevent missing activation due to queue failure
- `[ENHANCEMENT]` forces SSL unless DISABLE_SSL_FORCE is set (to true obviously :])

## 1.1.3

- `[ENHANCEMENT]` fake adapter now adds reference to info field for statements

## 1.1.2

- `[BUGFIX]` account activation was not triggered due to incorrect sidekiq config

## 1.1.1

- `[BUGFIX]` fixes docker-compose file running incorrect server command
- `[ENHANCEMENT]` makes docker services run migration before startup
- `[HOUSEKEEPING]` updates heroku doku

## 1.1.0

- `[ENHANCEMENT]` renames subscribers to ebics user to lessen complexity

## 1.0.1

- `[DEPS]` updates epics to work with sparkasse again
- `[HOUSEKEEPING]` makes travis build docker files on success

## 1.0.0

- `[FEATURE]` direct debits for API v2
- `[BUGFIX]` initial migration now setups initial user

## 0.9.1

- `[BUGFIX]` migrations not passing
- `[OTHERS]` updates dependencies because of vulnerabilities
- `[OTHERS]` replaces byebug with pry

## 0.9

- `[BUGFIX]` fixes setup issue

## 0.8

- `[BUGFIX]` dropped setup migrations restored

## 0.7.2.2

- Fix webhook signature mechanism

## 0.7.2.1

- Ignore access_token attribute in accounts#update V1 API call

## 0.7.2

- bound postgresql to version 9.6.1 (be careful! manual migration or local overriding of this is necessary)
- BankStatements are bound to a year now, as some banking institutes tend to reuse their bank statement sequence number every year

## 0.7.1.2

- Bugfix for new supervisord version and problems logging to stdout

## 0.7.1.1

- Bugfix in FetchStatements Worker

## 0.7.1

Make scheduler intervals configurable.

- Set interval between retrieval of bank statements via UPDATE_BANK_STATEMENTS_INTERVAL (in minutes / default: 30)
- Set interval between retrieval of processing status reports via UPDATE_PROCESSING_STATUS_INTERVAL (in minutes / default: 300)

## 0.7

We ditched jruby in favor of ruby. This is great news!
API Changes for V2:

- Events are now availabe for V2
- Credits higher than 120.000€ are now allowed
- Bic-less transactions are now allowed - be careful, your bank may get angry

## 0.6.1

We're now using supervisord to spawn processes on startup

## 0.6.0

Integrated CAMT.053 parsing

- It is now possible to switch between mt940 / camt53 for each account
- Statements are fetched more frequently w/ camt53

_Important_: Switching to C53 requires to remove old mt940 statements for the according account.
Checksum calculation will not match C53 and mt940 statements!

## 0.5.4

Bugfix for running latest migrations without complications

## 0.5.3

Minor features and optimizations regarding statements

- Expose a unique statement id so clients can use it to prevent duplicates while importing
- Optimize checksum calculation for statements, so similar looking entries are imported correctly

## 0.5.2

Bugfix release

- Handle exceptions when creating multiple bank statements at once
- Add a migration to clean up a previous migration fuckup and add webhook tokens to organizations

## 0.5.1

Bugfix release

- Migrations run properly on setup
- Updated documentation
- Updated docker compose file

## 0.5.0

This release is a major rewrite of the way we handle incoming data on statements and transactions.
We now embrace the concept of account statements which include multiple transactions. It allows us
to store raw MT940 data economically. Moreover, we can easily rebuild statement data in case of
issues we are having with MT940 parsing.

- Store all incoming bank statements in a separate table
- Link account statements to imported bank statements
- Rebuild statement data from bank statements, as we had an issue with MT940 parsing
- Update to latest CMXL code to resolve issues with MT940 parsing.

In addition to that, this release also includes a few additions in preparation of our upcoming
distributed signature feature:

- Users can add their subscriber id (only one) for each account via non-management API endpoint
- Expose more data on accounts (include subscriber for current user)

## 0.4.0

This release focuses on how to authenticate. There is an accompanying project to perform user
on-boarding and managing core data. By switching to OAuth we can provide a nice UI without having
to include it in the box.

- Drop support for organization management tokens
- Add user admin flag to limit access to management features

## 0.3.0

- Expose events via https://box/events (including information about webhook deliveries)
- Expose raw MT940 in statements when requested via header or query parameter
- Harden security around webhook payload verification
- Fix issues with interactive documentation using http instead of https
- Fix minor mistakes in documentation

## 0.2.0

This is the first release where we will apply the semantic versioning scheme. All changes listed
below have been added in the last few releases. Expect that we move forward in a more organized way.

- Switch to JRuby 9.0.5.0
- Proper support of OAuth Bearer tokens
- Track account balance
- Manual triggering of statement retrieval
- HTTP authentication for webhooks
- Fallback to non-T subscribers if none exists
- Improved onboarding API (INI letter, access tokens, etc.)
- Additions to documentation
- Automatic host detection for documentation
- Minimal fake backend for triggering statements (immediate dev feedback)
- Proper support for Deutsche Bank's MT940 file format
- Proper support for Deutsche Bank's sub-accounts format
- Improved security by self-managed docker base images
- Reduced JVM memory footprint
- Additional logging for queued jobs
- Everything else ;)
