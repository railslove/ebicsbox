# frozen_string_literal: true

require "sidekiq-scheduler"
require "active_support/all"
require "camt_parser"
require "epics"
require "sequel"

require_relative "../business_processes/import_bank_statement"
require_relative "../business_processes/import_statements"
require_relative "../models/account"

module Box
  module Jobs
    class QueueFetchStatements
      include Sidekiq::Worker
      sidekiq_options queue: "check.statements", retry: false

      def perform(account_ids = [], options = {})
        log(:debug, "Queue fetch statements")
        account_ids = Account.all_active_ids if account_ids.empty?

        account_ids.each do |account_id|
          FetchStatements.perform_async(account_id, options)
        end
      end

      private

      def log(type, message, data = {})
        data = data.map { |k, v| "#{k}=#{v}" }.join(" ")
        Box.logger.public_send(type, "[#{self.class.name}] #{message} #{data}")
      end
    end
  end
end
