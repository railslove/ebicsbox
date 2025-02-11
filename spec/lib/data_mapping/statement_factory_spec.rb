# frozen_string_literal: true

require_relative "../../../lib/data_mapping/statement_factory"

RSpec.describe DataMapping::StatementFactory do
  describe "#call" do
    context "when account statements_format is camt53" do
      it "returns a Camt53::Statement" do
        raw_bank_statement = File.read("spec/fixtures/camt_statement.xml")
        account = Fabricate(:activated_account, statements_format: "camt53")

        statement_factory = described_class.new(raw_bank_statement, account)

        expect(statement_factory.call).to be_a(DataMapping::Camt53::Statement)
      end
    end

    context "when account statements_format is cmxl" do
      it "returns a Cmxl::Statement" do
        raw_bank_statement = File.read("spec/fixtures/single_valid.mt940")
        account = Fabricate(:activated_account, statements_format: "mt940")

        statement_factory = described_class.new(raw_bank_statement, account)

        expect(statement_factory.call).to be_a(DataMapping::Cmxl::Statement)
      end
    end
  end
end
