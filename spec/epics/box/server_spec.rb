module Epics
  module Box
    RSpec.describe Server do
      describe 'GET :account/statements' do
        let(:account) { Account.create(iban: SecureRandom.uuid) }

        it 'returns an empty array for new accounts' do
          get "#{account.iban}/statements"
          expect_json([])
        end

        it 'returns properly formatted statements' do
          statement = Statement.create account_id: account.id
          get "#{account.iban}/statements"
          expect_json '0.statement', { account_id: account.id }
        end

        it 'passes page and per_page params to statement retrieval function' do
          allow(Statement).to receive(:paginated_by_account) { double(all: [])}
          get "#{account.iban}/statements?page=4&per_page=2"
          expect(Statement).to have_received(:paginated_by_account).with(account.id, per_page: 2, page: 4)
        end

        it 'allows to filter results by a date range'
      end

      describe 'POST /accounts' do
        context 'invalid body' do
          before { post 'accounts', {} }

          it 'rejects empty posts' do
            expect_status 400
          end

          it 'rejects empty posts' do
            expect_json_types error: :string
          end
        end

        it 'stores new minimal accounts' do
          expect {
            post 'accounts', { name: 'Test account', iban: 'my-iban', bic: 'my-iban' }
          }.to change {
            Account.count
          }
        end
      end

      describe 'PUT /accounts/:id' do
        let(:account) { Account.create(name: 'name', iban: 'old-iban', bic: 'old-bic') }

        context 'activated account' do
          before { account.update(activated_at: 1.hour.ago) }

          it 'cannot change iban' do
            expect { put "accounts/#{account.iban}", { iban: 'new-iban' } }.to_not change { account.reload.iban }
          end

          it 'cannot change bic' do
            expect { put "accounts/#{account.iban}", { bic: 'new-bic' } }.to_not change { account.reload.bic }
          end

          it 'ignores iban if it did not change' do
            expect { put "accounts/#{account.iban}", { iban: 'old-iban', name: 'new name' } }.to change { account.reload.name }
          end
        end

        context 'inactive account' do
          before { account.update(activated_at: nil) }

          it 'can change iban' do
            expect { put "accounts/#{account.iban}", { iban: 'new-iban' } }.to change { account.reload.iban }
          end

          it 'can change iban' do
            expect { put "accounts/#{account.iban}", { bic: 'new-bic' } }.to change { account.reload.bic }
          end
        end
      end
    end
  end
end
