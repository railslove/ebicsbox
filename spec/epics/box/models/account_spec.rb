module Epics
  module Box
    RSpec.describe Account do
      describe '.all_ids' do
        it 'returns an empty array if no accounts are created yet' do
          expect(Account.all_ids).to eq([])
        end

        it 'returns all account ids' do
          accounts = Array.new(2).map { Account.create }
          expect(Account.all_ids).to eq(accounts.map(&:id))
        end
      end

      describe '#imported_at!' do
        let(:account) { Account.create }

        it 'adds a new import for the account and the given day' do
          expect{ account.imported_at!(Date.today) }.to change { DB[:imports].where(account_id: account.id).count }.by(1)
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
