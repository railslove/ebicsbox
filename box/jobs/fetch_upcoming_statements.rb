# frozen_string_literal: true

require 'sidekiq-scheduler'
require 'active_support/all'
require 'camt_parser'
require 'cmxl'
require 'epics'
require 'sequel'

require_relative '../business_processes/import_bank_statement'
require_relative '../business_processes/import_statements'
require_relative '../models/account'

module Box
  module Jobs
    class FetchUpcomingStatements
      include Sidekiq::Worker
      sidekiq_options queue: 'check.statements'

      attr_accessor :options

      def self.for_account(account_id, options = {})
        new(options).fetch_for_account(account_id)
      end

      def initialize(options = {})
        self.options = options
      end

      def perform(options = {})
        self.options = options.symbolize_keys!

        account_ids = options.fetch(:account_ids, [])
        account_ids = Account.all_active_ids if account_ids.empty?

        account_ids.each do |account_id|
          fetch_for_account(account_id)
        end
      end

      def fetch_for_account(account_id)
        account = Account.first!(id: account_id)

        if account.statements_format != 'mt940'
          Box.logger.info("[Jobs::FetchUpcomingStatements] Skip VMK for #{account_id}. Currently only MT942 is supported")
          return
        end

        vmk_data = account.transport_client.VMK(safe_from.to_s(:db), safe_to.to_s(:db))
        chunks = Cmxl.parse(vmk_data)
        import_stats = import_to_database(chunks, account)

        Box.logger.info("[Jobs::FetchUpcomingStatements] Imported #{chunks.count} VMK(s) for Account ##{account_id}.")

        import_stats
      rescue Sequel::NoMatchingRow => e
        Box.logger.error("[Jobs::FetchUpcomingStatements] Could not find Account ##{account_id}")
      rescue Epics::Error::BusinessError => e
        # The BusinessError can occur when no new statements are available
        Box.logger.error("[Jobs::FetchUpcomingStatements] EBICS error. id=#{account_id} reason='#{e.message}'")
      end

      def import_to_database(chunks, account)
        chunks.reduce(total: 0, imported: 0) do |memo, chunk|
          bank_statement = BusinessProcesses::ImportBankStatement.from_cmxl(chunk, account)
          result = BusinessProcesses::ImportStatements.from_bank_statement(bank_statement, upcoming: true)

          { total: memo[:total] + result[:total], imported: memo[:imported] + result[:imported] }
        rescue BusinessProcesses::ImportBankStatement::InvalidInput => e
          Box.logger.error("[Jobs::FetchUpcomingStatements] #{e} account_id=#{account.id}")
          memo
        end
      end

      private

      def safe_from
        options.fetch(:from, Date.today)
      end

      def safe_to
        options.fetch(:to, 180.days.from_now.to_date)
      end
    end
  end
end
