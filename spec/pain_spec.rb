require_relative '../lib/pain'

RSpec.describe Pain do
  describe 'invalid PAIN data' do
    it 'handles random string' do
      expect{ described_class.from_xml('random string') }.to raise_error(Pain::UnknownInput)
    end

    it 'handles empty string' do
      expect{ described_class.from_xml('') }.to raise_error(Pain::UnknownInput)
    end

    it 'handles nil' do
      expect{ described_class.from_xml(nil) }.to raise_error(Pain::UnknownInput)
    end
  end
  describe 'SEPA Credits' do
    context "Version 03" do
      # Please check the file contents to understand where data is coming from
      let(:xml) { File.read('spec/fixtures/pain_credit_03.xml') }

      describe 'public api' do
        subject { described_class.from_xml(xml) }

        it 'responds to #as_json' do
          expect(subject.as_json).to be_a(Hash)
        end

        it 'responds to #to_hash' do
          expect(subject.to_hash).to be_a(Hash)
        end

        it 'responds to #to_h' do
          expect(subject.to_h).to be_a(Hash)
        end
      end

      describe 'general meta data' do
        subject { described_class.from_xml(xml).to_h }

        it "extracts the document's id" do
          expect(subject[:id]).to eq('EBICS-BOX/A96029885148366AE95082')
        end

        it "has type credit" do
          expect(subject[:type]).to eq('credit')
        end

        it "extracts the date when created" do
          expect(subject[:created_at]).to eq('2016-03-23T09:56:36+01:00')
        end

        it "extracts its transactions_count" do
          expect(subject[:transactions_count]).to eq(1)
        end

        it "extracts its total amount" do
          expect(subject[:total_amount]).to eq(1000.13)
        end

        it "converts total amount to BigDecimal" do
          expect(subject[:total_amount]).to be_a(BigDecimal)
        end

        it "extracts its initiating party" do
          expect(subject[:initiating_party]).to eq({ name: 'QA Konto BV' })
        end

        it "extracts all its payments" do
          expect(subject[:payments]).to be_a(Array)
          expect(subject[:payments].size).to eq(2)
        end
      end

      describe 'nested payments' do
        subject { described_class.from_xml(xml).to_h[:payments].first }

        it "extracts the payment's id" do
          expect(subject[:id]).to eq('EBICS-BOX/A96029885148366AE95082/1')
        end

        it "extracts the execution_date" do
          expect(subject[:execution_date]).to eq('2016-03-23')
        end

        it "extracts its account" do
          expect(subject[:account]).to eq("QA Konto BV")
        end

        it "extracts its iban" do
          expect(subject[:iban]).to eq("DE36250400900001234555")
        end

        it "extracts its bic" do
          expect(subject[:bic]).to eq("XBANDECG")
        end

        it "extracts all its transactions" do
          expect(subject[:transactions]).to be_a(Array)
          expect(subject[:transactions].size).to eq(1)
        end
      end

      describe 'deeply nested transactions' do
        subject { described_class.from_xml(xml).to_h[:payments].first[:transactions].first }

        it "extracts the eref" do
          expect(subject[:eref]).to eq('veu-eref-31')
        end

        it "extracts the name" do
          expect(subject[:name]).to eq('Max Mustermann')
        end

        it "extracts its amount" do
          expect(subject[:amount]).to eq(1000.13)
        end

        it "converts its amount to BigDecimal" do
          expect(subject[:amount]).to be_a(BigDecimal)
        end

        it "extracts its iban" do
          expect(subject[:iban]).to eq("DE64512308000000064167")
        end

        it "extracts its bic" do
          expect(subject[:bic]).to eq("WIREDEMMXXX")
        end

        it "extracts its remittance_information" do
          expect(subject[:remittance_information]).to eq("BV Test 1")
        end
      end
    end
  end

  describe 'SEPA Debits' do
    context "Version 02" do
      # Please check the file contents to understand where data is coming from
      let(:xml) { File.read('spec/fixtures/pain_debit_02.xml') }

      describe 'public api' do
        subject { described_class.from_xml(xml) }

        it 'responds to #as_json' do
          expect(subject.as_json).to be_a(Hash)
        end

        it 'responds to #to_hash' do
          expect(subject.to_hash).to be_a(Hash)
        end

        it 'responds to #to_h' do
          expect(subject.to_h).to be_a(Hash)
        end
      end

      describe 'general meta data' do
        subject { described_class.from_xml(xml).to_h }

        it "extracts the document's id" do
          expect(subject[:id]).to eq('EBICS-BOX/091289075DAA0AD81C0659')
        end

        it "has type direct_debit" do
          expect(subject[:type]).to eq('direct_debit')
        end

        it "extracts the date when created" do
          expect(subject[:created_at]).to eq('2016-01-25T16:58:37+01:00')
        end

        it "extracts its transactions_count" do
          expect(subject[:transactions_count]).to eq(1)
        end

        it "extracts its total amount" do
          expect(subject[:total_amount]).to eq(1.23)
        end

        it "converts total amount to BigDecimal" do
          expect(subject[:total_amount]).to be_a(BigDecimal)
        end

        it "extracts its initiating party" do
          expect(subject[:initiating_party]).to eq({ name: 'Test Account' })
        end

        it "extracts all its payments" do
          expect(subject[:payments]).to be_a(Array)
          expect(subject[:payments].size).to eq(1)
        end
      end

      describe 'nested payments' do
        subject { described_class.from_xml(xml).to_h[:payments].first }

        it "extracts the payment's id" do
          expect(subject[:id]).to eq('EBICS-BOX/091289075DAA0AD81C0659/1')
        end

        it "extracts the collection_date" do
          expect(subject[:collection_date]).to eq('2016-01-27')
        end

        it "extracts its account" do
          expect(subject[:account]).to eq("Test Account")
        end

        it "extracts its iban" do
          expect(subject[:iban]).to eq("AL90208110080000001039531801")
        end

        it "extracts its bic" do
          expect(subject[:bic]).to be_nil
        end

        it "extracts all its transactions" do
          expect(subject[:transactions]).to be_a(Array)
          expect(subject[:transactions].size).to eq(1)
        end
      end

      describe 'deeply nested transactions' do
        subject { described_class.from_xml(xml).to_h[:payments].first[:transactions].first }

        it "extracts the eref" do
          expect(subject[:eref]).to eq('de340dc715540d7ba189d9daff3febf7')
        end

        it "extracts the name" do
          expect(subject[:name]).to eq('Some person')
        end

        it "extracts its amount" do
          expect(subject[:amount]).to eq(1.23)
        end

        it "converts its amount to BigDecimal" do
          expect(subject[:amount]).to be_a(BigDecimal)
        end

        it "extracts its iban" do
          expect(subject[:iban]).to eq("AL90208110080000001039531801")
        end

        it "extracts its bic" do
          expect(subject[:bic]).to eq("DABAIE2D")
        end

        it "extracts its mandate info" do
          expect(subject[:mandate]).to eq(id: "1123", signed_on: "2016-01-25")
        end

        it "extracts its remittance_information" do
          expect(subject[:remittance_information]).to eq("Give me all your moneyz")
        end
      end
    end
  end
end
