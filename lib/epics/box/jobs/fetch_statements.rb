require 'cmxl'
require 'epics'
require 'sequel'

require_relative '../business_processes/import_bank_statement'
require_relative '../business_processes/import_statements'
require_relative '../models/account'

module Epics
  module Box
    module Jobs
      class FetchStatements
        class << self
          def process!(message)
            message[:account_ids].each do |account_id|
              fetch_new_statements(account_id)
            end
          end

          # Fetch all new statements for a single account since its last import. Each account import
          # can fail and should not affect imports for other accounts.
          def fetch_new_statements(account_id, from = 30.days.ago.to_date, to = Date.today)
            account = Account.first!(id: account_id)
            method = account.statements_format

            chunks = self.send(method, account.transport_client, from, to)

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
            Box.logger.error { "[Jobs::FetchStatements] EBICS error. id={account_id} reason='#{ex.message}'" }
          end

          def import_to_database(chunks, account)
            chunks.map do |chunk|
              begin
                bank_statement = BusinessProcesses::ImportBankStatement.from_cmxl(chunk, account)
                res = BusinessProcesses::ImportStatements.from_bank_statement(bank_statement)
              rescue BusinessProcesses::ImportBankStatement::InvalidInput => ex
                Box.logger.error { "[Jobs::FetchStatements] #{ex} account_id=#{account.id}" }
                { total: 0, imported: 0 }
              end
            end.reduce({ total: 0, imported: 0 }) do |memo, chunk_stats|
              {
                total: memo[:total] + chunk_stats[:total],
                imported: memo[:imported] + chunk_stats[:imported]
              }
            end
          end

          # TODO: Refactor this shitty implementation
          def update_account_last_import(account, to)
            imported_at = account.last_imported_at
            if !imported_at || imported_at <= to
              account.imported_at!(Time.now)
            end
          end

          private
          def camt53(client, from, to)
            combined_camt = client.C53(from.to_s(:db), to.to_s(:db))
            combined_camt.map{ |chunk| CamtParser::String.parse(chunk).statements }.flatten
          end

          def mt940(client, from, to)
            combined_mt940 = client.STA(from.to_s(:db), to.to_s(:db))
            Cmxl.parse(combined_mt940)
          end
        end
      end
    end
  end
end
