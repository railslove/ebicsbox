#!/bin/sh

# migrate db
bin/migrate

# Hand off to the CMD
exec "$@"
