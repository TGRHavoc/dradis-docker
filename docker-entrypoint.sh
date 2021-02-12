#!/bin/bash

# Exit the script in case of errors
set -e

SECRET_KEY_BASE="${SECRET_KEY_BASE:-$(rake secret)}"
export SECRET_KEY_BASE

RAILS_SERVE_STATIC_FILES="true"
export RAILS_SERVE_STATIC_FILES

cp -n /dradis/db/production.sqlite3 /dbdata/
cp -r -n /dradis/templates_orig/* /dradis/templates/
#chown -R dradis /dbdata/
chmod -R u+w /dbdata/

#bundle exec rails server -b 0.0.0.0
ruby bin/rails server 
