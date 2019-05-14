# frozen_string_literal: true

env = ENV.fetch('RACK_ENV', :development)
if env.to_s != 'production'
  # Load environment from file
  require 'dotenv'
  Dotenv.load
end

# Load environment
require 'bundler'
Bundler.setup(:default, env)

# Make sure output is written immediately
$stdout.sync = true

# Start processing of queued jobs
require_relative './bootstrap'

require_relative '../box/jobs/credit'
require_relative '../box/jobs/debit'
require_relative '../box/jobs/fetch_processing_status'
require_relative '../box/jobs/fetch_statements'
require_relative '../box/jobs/webhook'
require_relative '../box/jobs/check_activation'
