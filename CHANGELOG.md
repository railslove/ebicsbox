# Changelog

* Persist an account's last error in database, so users can check on their accounts
## 0.3.0

* Expose events via https://box/events (including information about webhook deliveries)
* Expose raw MT940 in statements when requested via header or query parameter
* Harden security around webhook payload verification

## 0.2.0

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
