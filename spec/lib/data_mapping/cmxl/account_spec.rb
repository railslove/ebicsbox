# frozen_string_literal: true

require_relative "../../../../lib/data_mapping/cmxl/account"

RSpec.describe DataMapping::Cmxl::Account do
  let(:cmxl_file) { File.read("spec/fixtures/single_valid.mt940") }
  let(:raw_bank_statement) do
    statement = Cmxl.parse(cmxl_file).first
    statement.account_identification
  end
  let(:account) { described_class.new(raw_bank_statement) }

  describe "delegated methods" do
    it "delegates account_number to raw_bank_statement" do
      expect(account.account_number).to be_instance_of(String)
    end
  end

  describe "#iban" do
    context "when IBAN is present" do
      let(:cmxl_file) { File.read("spec/fixtures/single_valid_swift.mt940") }
      it "returns the IBAN" do
        expect(account.iban).to be_instance_of(String)
      end
    end

    context "when IBAN is not present" do
      # let(:cmxl_file) { File.read("spec/fixtures/single_valid_2016-03-15.mt940") }

      it "returns the source" do
        expect(account.iban).to eq(raw_bank_statement.source)
      end
    end
  end
end
