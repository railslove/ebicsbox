module Epics
  module Box
    RSpec.describe Server do
      describe 'GET :account/statements' do
        let(:account) { Account.create(iban: SecureRandom.uuid) }

        it 'returns an empty array for new accounts' do
          get "#{account.iban}/statements", format: 'json'
          expect_json([])
        end

        it 'returns properly formatted statements' do
          statement = Statement.create account_id: account.id
          get "#{account.iban}/statements", format: 'json'
          expect_json '0.statement', { account_id: account.id }
        end

        it 'passes page and per_page params to statement retrieval function' do
          allow(Statement).to receive(:paginated_by_account) { double(all: [])}
          get "#{account.iban}/statements?page=4&per_page=2", format: 'json'
          expect(Statement).to have_received(:paginated_by_account).with(account.id, per_page: 2, page: 4)
        end

        it 'allows to filter results by a date range'
      end
    end
  end
end
