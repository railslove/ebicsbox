#!/bin/sh

# migrate db
bin/migrate

bundle exec rake after_migration:calculate_bank_statements_sha

# Hand off to the CMD
exec "$@"
