require 'cmxl'

require_relative '../lib/epics/box'
require_relative '../lib/epics/box/models/statement'
require_relative '../lib/epics/box/models/bank_statement'
require_relative '../lib/epics/box/business_processes/import_bank_statement'
require_relative '../lib/epics/box/business_processes/import_statements'

Sequel.migration do
  up do
    create_table :bank_statements do
      primary_key :id
      Integer :account_id
      String :remote_account
      String :sequence
      BigDecimal :opening_balance, size: [15, 2]
      BigDecimal :closing_balance, size: [15, 2]
      Integer :transaction_count
      Date :fetched_on
      String :content
    end

    add_column :statements, :bank_statement_id, Integer

    # Reload sequel schemas
    Epics::Box::BankStatement.set_dataset :bank_statements
    Epics::Box::Statement.set_dataset :statements

    affected_statements_query = Epics::Box::Statement.where('raw_data IS NOT NULL')

    # Build bank statements table from raw statements data
    affected_statements_query.all.each do |statement|
      Epics::Box::BusinessProcesses::ImportBankStatement.import_all_from_mt940(statement.raw_data, statement.account)
    end

    # Delete all statements which do not contain any valid data
    affected_statements_query.delete

    # Rebuild statements from bank statements
    Epics::Box::BankStatement.all.each do |bank_statement|
      Epics::Box::BusinessProcesses::ImportStatements.from_bank_statement(bank_statement)
    end

    drop_column :statements, :raw_data
  end

  down do
    add_column :statements, :raw_data, String
    drop_column :statements, :bank_statement_id
    drop_table :bank_statements
  end
end
