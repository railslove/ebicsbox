require 'cmxl'
require 'camt_parser'

Sequel.migration do
  up do
    add_column :bank_statements, :year, Integer
    PARSERS = { 'mt940' => Cmxl, 'camt53' => CamtParser::Format053::Statement }
    self[:bank_statements].all do |bank_statement|
      sta_format = self[:accounts].where(id: bank_statement[:account_id]).first[:statements_format]
      parser = PARSERS.fetch(sta_format, Cmxl)
      result = parser.parse(bank_statement[:content])
      transactions = result.kind_of?(Array) ? result.first.transactions : result.transactions
      self[:bank_statements].where(id: bank_statement[:id]).update(year: transactions&.first&.date&.year)
    end
  end

  down do
    drop_column :bank_statements, :year
  end
end
