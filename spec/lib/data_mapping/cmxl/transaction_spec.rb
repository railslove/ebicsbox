# frozen_string_literal: true

require_relative "../../../../lib/data_mapping/cmxl/transaction"

RSpec.describe DataMapping::Cmxl::Transaction do
  let(:cmxl_file) { File.read("spec/fixtures/single_valid.mt940") }
  let(:raw_bank_statement) do
    statement = Cmxl.parse(cmxl_file).first
    statement.transactions.first
  end
  let(:transaction) { described_class.new(raw_bank_statement) }

  describe "delegated methods" do
    it "delegates amount_in_cents to raw_bank_statement" do
      expect(transaction.amount_in_cents).to be_instance_of(Integer)
    end

    it "delegates bank_reference to raw_bank_statement" do
      expect(transaction.bank_reference).to be_instance_of(String)
    end

    it "delegates credit? to raw_bank_statement" do
      expect(transaction.credit?).to be(true).or be(false)
    end

    it "delegates debit? to raw_bank_statement" do
      expect(transaction.debit?).to be(true).or be(false)
    end

    it "delegates reference to raw_bank_statement" do
      expect(transaction.reference).to be_instance_of(String)
    end

    it "delegates sign to raw_bank_statement" do
      expect(transaction.sign).to be_instance_of(Integer)
    end
  end

  describe "#bic" do
    it "returns the BIC" do
      expect(transaction.bic).to be_instance_of(String)
    end
  end

  describe "#creditor_identifier" do
    let(:cmxl_file) { File.read("spec/fixtures/single_valid_swift.mt940") }

    it "returns the creditor identifier" do
      expect(transaction.creditor_identifier).to be_instance_of(String)
    end
  end

  describe "#date" do
    it "returns the value date" do
      expect(transaction.date).to be_instance_of(Date)
    end
  end

  describe "#description" do
    it "returns the additional information" do
      expect(transaction.description).to be_instance_of(String)
    end
  end

  describe "#entry_date" do
    it "returns the booking date" do
      expect(transaction.entry_date).to be_instance_of(Date)
    end
  end

  describe "#eref" do
    let(:cmxl_file) { File.read("spec/fixtures/single_valid_swift.mt940") }

    it "returns the end to end reference" do
      expect(transaction.eref).to be_instance_of(String)
    end
  end

  describe "#iban" do
    let(:cmxl_file) { File.read("spec/fixtures/single_valid_swift.mt940") }

    it "returns the IBAN" do
      expect(transaction.iban).to be_instance_of(String)
    end
  end

  describe "#information" do
    it "returns the payment information" do
      expect(transaction.information).to be_instance_of(String)
    end
  end

  describe "#mref" do
    let(:cmxl_file) { File.read("spec/fixtures/single_valid_swift.mt940") }

    it "returns the mandate reference" do
      expect(transaction.mref).to be_instance_of(String)
    end
  end

  describe "#name" do
    it "returns the name" do
      expect(transaction.name).to be_instance_of(String)
    end
  end

  describe "#svwz" do
    let(:cmxl_file) { File.read("spec/fixtures/single_valid_swift.mt940") }

    it "returns the remittance information" do
      expect(transaction.svwz).to be_instance_of(String)
    end
  end

  describe "#swift_code" do
    it "returns the swift code" do
      expect(transaction.swift_code).to be_instance_of(String)
    end
  end

  describe "#transaction_id" do
    it "returns the transaction ID" do
      expect(transaction.transaction_id).to be_instance_of(String)
    end
  end
end
