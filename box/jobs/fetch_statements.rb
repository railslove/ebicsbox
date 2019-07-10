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
    class FetchStatements
      include Sidekiq::Worker
      sidekiq_options queue: 'check.statements'

      attr_accessor :from, :to

      def perform(account_id, options = {})
        return unless account_id

        options.symbolize_keys!

        self.from = options.fetch(:from, 7.days.ago.to_date)
        self.to = options.fetch(:to, Date.today)

        fetch_for_account(account_id)
      end

      # Fetch all new statements for a single account since its last import. Each account import
      # can fail and should not affect imports for other accounts.
      def fetch_for_account(account_id)
        account = Account.first!(id: account_id)
        method = account.statements_format

        chunks = send(method, account.transport_client, from, to)

        # Store all fetched bank statements for later usage
        import_stats = import_to_database(chunks, account)

        # Update imported at timestamp
        update_account_last_import(account, to)

        Box.logger.info { "[Jobs::FetchStatements] Imported bank statements. id=#{account_id} bank_statement_count=#{chunks.count}" }

        import_stats
      rescue Sequel::NoMatchingRow => ex
        Box.logger.error { "[Jobs::FetchStatements] Could not find account. account_id=#{account_id}" }
      rescue Epics::Error::BusinessError => ex
        # The BusinessError can occur when no new statements are available
        Box.logger.error { "[Jobs::FetchStatements] EBICS error. id=#{account_id} reason='#{ex.message}'" }
      end

      def import_to_database(chunks, account)
        chunks.map do |chunk|
          begin
            bank_statement = BusinessProcesses::ImportBankStatement.from_cmxl(chunk, account)
            BusinessProcesses::ImportStatements.from_bank_statement(bank_statement)
          rescue BusinessProcesses::ImportBankStatement::InvalidInput => ex
            Box.logger.error { "[Jobs::FetchStatements] #{ex} account_id=#{account.id}" }
            { total: 0, imported: 0 }
          end
        end.reduce(total: 0, imported: 0) do |memo, chunk_stats|
          {
            total: memo[:total] + chunk_stats[:total],
            imported: memo[:imported] + chunk_stats[:imported]
          }
        end
      end

      # TODO: Refactor this shitty implementation
      def update_account_last_import(account, to)
        imported_at = account.last_imported_at
        account.imported_at!(Time.now) if !imported_at || imported_at <= to
      end

      private

      def camt53(client, from, to)
        combined_camt = client.C53(from.to_s(:db), to.to_s(:db))
        combined_camt.map { |chunk| CamtParser::String.parse(chunk).statements }.flatten
      end

      def mt940(client, from, to)
        combined_mt940 = client.STA(from.to_s(:db), to.to_s(:db))
        Cmxl.parse(combined_mt940)
      end
    end
  end
end
