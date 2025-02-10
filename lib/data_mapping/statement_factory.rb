require_relative "../../lib/data_mapping/camt53/statement"
require_relative "../../lib/data_mapping/cmxl/statement"

module DataMapping
  class StatementFactory
    attr_reader :raw_bank_statement, :account

    def initialize(raw_bank_statement, account)
      @raw_bank_statement = raw_bank_statement
      @account = account
    end

    def call
      case account.statements_format
      when "camt53"
        DataMapping::Camt53::Statement.new(raw_bank_statement)
      when "mt940"
        DataMapping::Cmxl::Statement.new(raw_bank_statement)
      end
    end
  end
end
