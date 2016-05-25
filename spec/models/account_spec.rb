require 'active_support/all'

module Box
  RSpec.describe Account do

    describe '#transport_client' do
      subject(:account) { described_class.create(mode: "Fake") }

      context 'no subscriber added' do
        it 'fails with an no transport client exceptiopn' do
          expect { account.transport_client }.to raise_error(Account::NoTransportClient)
        end
      end

      context 'no activated subscriber available' do
        before { account.add_subscriber(activated_at: nil) }

        it 'fails with an no transport client exceptiopn' do
          expect { account.transport_client }.to raise_error(Account::NoTransportClient)
        end
      end

      context 'activated T and another subscriber available' do
        before do
          account.add_subscriber(remote_user_id: 'E-USER', signature_class: 'E', activated_at: Date.new(2015, 1, 1))
          account.add_subscriber(remote_user_id: 'T-USER', signature_class: 'T', activated_at: Date.new(2015, 1, 1))
        end

        it 'returns a client instance' do
          expect(account.transport_client).to respond_to(:STA)
        end

        it 'returns the T signature class client' do
          expect(account.transport_client.setup_args).to include('T-USER')
        end
      end

      context 'no activated T subscriber' do
        before do
          account.add_subscriber(signature_class: 'E', activated_at: Date.new(2015, 1, 1))
        end

        it 'falls back to non-T subscriber' do
          expect(account.transport_client).to respond_to(:STA)
        end
      end
    end

    describe '.all_active_ids' do
      it 'returns an empty array if no accounts are created yet' do
        expect(described_class.all_active_ids).to eq([])
      end

      it 'returns all account ids' do
        activated_account = described_class.create
        inactive_account = described_class.create

        Subscriber.create(account: activated_account, activated_at: Time.now)
        Subscriber.create(account: inactive_account, activated_at: nil)

        expect(described_class.all_active_ids).to eq([activated_account.id])
      end
    end

    describe '#pain_attributes_hash' do
      subject { Account.create(name: 'name', bic: 'bic', iban: 'iban', creditor_identifier: 'ci') }

      context 'activated account' do
        before { subject.add_subscriber(activated_at: 1.day.ago) }

        it 'returns only relevant pain attributes' do
          expect(subject.pain_attributes_hash.keys).to eq([:name, :bic, :iban, :creditor_identifier])
        end
      end

      context 'not yet activated account' do
        it 'fails with an exception' do
          expect { subject.credit_pain_attributes_hash }.to raise_error(Account::NotActivated)
        end
      end
    end

    describe '#credit_pain_attributes_hash' do
      subject { Account.create(name: 'name', bic: 'bic', iban: 'iban', creditor_identifier: 'ci') }

      context 'activated account' do
        before { subject.add_subscriber(activated_at: 1.day.ago) }

        it 'returns only relevant pain attributes' do
          expect(subject.credit_pain_attributes_hash.keys).to eq([:name, :bic, :iban])
        end
      end

      context 'not yet activated account' do
        it 'fails with an exception' do
          expect { subject.credit_pain_attributes_hash }.to raise_error(Account::NotActivated)
        end
      end
    end

    describe '#last_imported_at' do
      let(:account) { Account.create }

      context 'account has just been created' do
        it 'returns nil' do
          expect(account.last_imported_at).to be_nil
        end
      end

      context 'account has already some imports' do
        before do
          account.imported_at!(2.days.ago)
          account.imported_at!(3.days.ago)
        end

        it 'returns date of last import' do
          expect(account.last_imported_at).to eq(2.days.ago.to_date)
        end
      end
    end

    describe 'config' do
      let(:account) { Account.new }

      it 'returns a configuration object' do
        expect(account.config).to be_kind_of(Box::Account::Config)
      end

      describe '.activation_check_interval' do
        context "when no value is specified" do
          before { account.set(config: {}) }

          it 'falls back to global default' do
            expect(account.config.activation_check_interval).to eq(Box.configuration.activation_check_interval)
          end
        end

        context "when a value is specified" do
          before { account.set(config: { activation_check_interval: 10 }) }

          it 'uses this value' do
            expect(account.config.activation_check_interval).to eq(10)
          end
        end
      end
    end
  end
end
