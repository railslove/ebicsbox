#!/bin/sh

# migrate db
bin/migrate

bundle exec rake after_migration:calculate_bank_statements_sha
bundle exec rake after_migration:recalculate_statements_sha
bundle exec rake after_migration:copy_partners

# Hand off to the CMD
exec "$@"
