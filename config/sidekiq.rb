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
require_relative '../box/jobs/fetch_upcoming_statements'
require_relative '../box/jobs/webhook'
require_relative '../box/jobs/check_activation'

require 'sidekiq'
require 'sidekiq-scheduler'

if ENV['ROLLBAR_ACCESS_TOKEN']
  require 'rollbar'

  Rollbar.configure do |config|
    config.access_token = ENV['ROLLBAR_ACCESS_TOKEN']
    config.use_sidekiq
  end
end

if ENV['SENTRY_DSN']
  require 'raven'
  Raven.configure do |config|
    # Raven reports on the following environments
    config.environments = %w(development staging production)
  end
end

Sidekiq.configure_server do |config|
  config.on(:startup) do
    fetch_bank_statements_interval = ENV['UPDATE_BANK_STATEMENTS_INTERVAL'].to_i
    unless fetch_bank_statements_interval.zero?
      Sidekiq.set_schedule(
        'fetch_account_statements',
        every: "#{fetch_bank_statements_interval}m",
        class: 'Box::Jobs::QueueFetchStatements',
        queue: 'check.statements'
      )
    end

    update_processing_status_interval = ENV['UPDATE_PROCESSING_STATUS_INTERVAL'].to_i
    unless update_processing_status_interval.zero?
      Sidekiq.set_schedule(
        'update_processing_status',
        every: "#{update_processing_status_interval}m",
        class: 'Box::Jobs::QueueProcessingStatus',
        queue: 'check.orders'
      )
    end

    activate_ebics_user_interval = ENV['ACTIVATE_EBICS_USER_INTERVAL'].to_i
    unless activate_ebics_user_interval.zero?
      Sidekiq.set_schedule(
        'activate_ebics_user',
        every: "#{activate_ebics_user_interval}m",
        class: 'Box::Jobs::CheckActivation',
        queue: 'check.activations'
      )
    end

    upcoming_statements_interval = ENV['UPCOMING_STATEMENTS_INTERVAL'].to_i
    unless upcoming_statements_interval.zero?
      Sidekiq.set_schedule(
        'fetch_upcoming_account_statements',
        every: "#{upcoming_statements_interval}m",
        class: 'Box::Jobs::FetchUpcomingStatements',
        queue: 'check.statements'
      )
    end
  end
end
