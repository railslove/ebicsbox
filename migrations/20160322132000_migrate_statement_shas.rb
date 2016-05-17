# require_relative '../config/bootstrap'

require_relative '../box/models/bank_statement'
require_relative '../box/models/statement'
require_relative '../box/business_processes/import_bank_statement'
require_relative '../box/business_processes/import_statements'

Sequel.migration do
  up do
    add_column :statements, :public_id, :uuid, default: Sequel.function(:uuid_generate_v4)
    Box::Statement.set_dataset :statements

    # Delete all old statements
    Box::Statement.where("bank_statement_id IS NOT NULL").destroy

    # Re-Import all statements
    # Rebuild statements from bank statements
    Box::BankStatement.all.each do |bank_statement|
      Box::BusinessProcesses::ImportStatements.from_bank_statement(bank_statement)
    end
  end

  down do
    # Digest::SHA2.hexdigest([transaction.sha, transaction.date, transaction.amount_in_cents, transaction.sepa].join).to_s,
    drop_column :statements, :public_id
  end
end
