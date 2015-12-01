module Epics
  module Box
    RSpec.describe Account do
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
    end
  end
end
