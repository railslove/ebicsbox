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
    class FetchUpcomingStatementsError < StandardError; end

    class FetchUpcomingStatements
      include Sidekiq::Worker
      sidekiq_options queue: "check.statements", retry: false

      attr_accessor :options

      def perform(account_id, options = {})
        account = Account[account_id]
        raise FetchUpcomingStatementsError, "Account-ID missing" unless account

        self.options = options.symbolize_keys!

        fetch_for_account(account)
      end

      def fetch_for_account(account)
        if account.statements_format != "mt940"
          Box.logger.info("[Jobs::FetchUpcomingStatements] Skip VMK for #{account.id}. Currently only MT942 is supported")
          return
        end

        vmk_data = account.transport_client.VMK(safe_from.to_s(:db), safe_to.to_s(:db))
        return unless vmk_data

        chunks = Cmxl.parse(vmk_data)
        import_stats = import_to_database(chunks, account)

        Box.logger.info("[Jobs::FetchUpcomingStatements] Imported #{chunks.count} VMK(s) for Account ##{account.id}.")

        import_stats
      rescue Sequel::NoMatchingRow => _ex
        Box.logger.error("[Jobs::FetchUpcomingStatements] Could not find Account ##{account.id}")
      rescue Epics::Error::BusinessError => ex
        # The BusinessError can occur when no new statements are available
        Box.logger.error("[Jobs::FetchUpcomingStatements] EBICS error. id=#{account.id} reason='#{ex.message}'")
      end

      def import_to_database(chunks, account)
        chunks.reduce(total: 0, imported: 0) do |memo, chunk|
          bank_statement = BusinessProcesses::ImportBankStatement.from_cmxl(chunk, account)
          result = BusinessProcesses::ImportStatements.from_bank_statement(bank_statement, upcoming: true)

          {total: memo[:total] + result[:total], imported: memo[:imported] + result[:imported]}
        rescue BusinessProcesses::ImportBankStatement::InvalidInput => e
          Box.logger.error("[Jobs::FetchUpcomingStatements] #{e} account_id=#{account.id}")
          memo
        end
      end

      private

      def safe_from
        options&.dig(:from) || Date.today
      end

      def safe_to
        options&.dig(:to) || 30.days.from_now.to_date
      end
    end
  end
end
