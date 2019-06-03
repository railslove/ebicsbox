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

Sidekiq.configure_server do |config|
  config.on(:startup) do
    fetch_bank_statements_interval = ENV['UPDATE_BANK_STATEMENTS_INTERVAL'].to_i
    unless fetch_bank_statements_interval.zero?
      Sidekiq.set_schedule(
        'fetch_account_statements',
        every: "#{fetch_bank_statements_interval}m",
        class: 'Box::Jobs::FetchStatements',
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
  end
end
