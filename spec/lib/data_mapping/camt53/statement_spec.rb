# frozen_string_literal: true

require_relative "../../../../lib/data_mapping/camt53/statement"

RSpec.describe DataMapping::Camt53::Statement do
  let(:raw_bank_statement) do
    camt_file = File.read("spec/fixtures/camt_statement.xml")
    SepaFileParser::String.parse(camt_file).statements.first
  end
  let(:statement) { described_class.new(raw_bank_statement) }

  describe "#blank?" do
    context "when raw_bank_statement is nil" do
      let(:statement) { described_class.new(nil) }

      it "returns true when raw_bank_statement" do
        expect(statement.blank?).to be true
      end
    end

    it "returns false when raw_bank_statement is not blank" do
      expect(statement.blank?).to be false
    end
  end

  describe "#account_identification" do
    it "returns an object with an account_number method" do
      expect(statement.account_identification.account_number).to be_instance_of(String)
    end

    it "returns an object with a iban method" do
      expect(statement.account_identification.iban).to be_instance_of(String)
    end
  end

  describe "#closing_or_intermediary_balance" do
    it "returns an object with a amount method" do
      expect(statement.closing_or_intermediary_balance).to respond_to(:amount)
    end

    it "returns an object with a date method" do
      expect(statement.closing_or_intermediary_balance).to respond_to(:date)
    end

    it "returns an object with a sign method" do
      expect(statement.closing_or_intermediary_balance).to respond_to(:sign)
    end
  end

  describe "#sequence" do
    it "returns the legal identifier for a sequence" do
      expect(statement.sequence).to be_instance_of(String)
    end
  end

  describe "#opening_or_intermediary_balance" do
    it "returns an object with a amount method" do
      expect(statement.closing_or_intermediary_balance).to respond_to(:amount)
    end

    it "returns an object with a date method" do
      expect(statement.closing_or_intermediary_balance).to respond_to(:date)
    end

    it "returns an object with a sign method" do
      expect(statement.closing_or_intermediary_balance).to respond_to(:sign)
    end
  end

  describe "#source" do
    it "returns the source from raw_bank_statement" do
      expect(statement.source).not_to be_nil
    end
  end

  describe "#transactions" do
    it "returns the transactions from raw_bank_statement" do
      expect(statement.transactions).to all(be_instance_of(DataMapping::Camt53::Transaction))
    end
  end
end
