# require 'epics/box/models/statement'
# require 'epics/box/entities/statement'

module Epics
  module Box
    RSpec.describe Content do
      let(:organization) { Organization.create(name: 'Organization 1') }
      let(:other_organization) { Organization.create(name: 'Organization 2') }
      let(:user) { User.create(organization_id: organization.id, name: 'Some user', access_token: 'orga-user') }
      let(:statement) { Statement.new }

      describe 'GET :account/statements' do
        before { user }

        context 'account does not exist' do
          it 'returns a not found status' do
            get "NOT_EXISTING/statements", { 'Authorization' => "token #{user.access_token}" }
            expect_status 404
          end

          it 'returns a proper error message' do
            get "NOT_EXISTING/statements", { 'Authorization' => "token #{user.access_token}" }
            expect_json 'message', 'Your organization does not have an account with given IBAN!'
          end
        end

        context 'account owned by another organization' do
          let(:account) { other_organization.add_account(iban: SecureRandom.uuid) }

          it 'returns a not found status' do
            get "#{account.iban}/statements", { 'Authorization' => "token #{user.access_token}" }
            expect_status 404
          end

          it 'returns a proper error message' do
            get "#{account.iban}/statements", { 'Authorization' => "token #{user.access_token}" }
            expect_json 'message', 'Your organization does not have an account with given IBAN!'
          end
        end

        context 'account is owned by user\s organization' do
          let(:account) { organization.add_account(iban: SecureRandom.uuid) }

          it 'returns an empty array for new accounts' do
            get "#{account.iban}/statements", { 'Authorization' => 'token orga-user' }
            expect(response.body).to eq('[]')
          end

          describe 'response' do
            let!(:statement) { Statement.create account_id: account.id, swift_code: 'NTRF' }

            it 'includes account IBAN' do
              get "#{account.iban}/statements", { 'Authorization' => 'token orga-user' }
              expect_json '0.account', account.iban
            end

            it 'includes link to self' do
              get "#{account.iban}/statements", { 'Authorization' => 'token orga-user' }
              expect_json '0._links.self', "http://localhost:5000/#{account.iban}/statements/#{statement.id}"
            end

            it 'includes link to account' do
              get "#{account.iban}/statements", { 'Authorization' => 'token orga-user' }
              expect_json '0._links.account', "http://localhost:5000/#{account.iban}"
            end

            it 'includes transaction type' do
              get "#{account.iban}/statements", { 'Authorization' => 'token orga-user' }
              expect_json '0.transaction_type', "NTRF"
            end

            context 'linked to a transaction' do
              let(:transaction) { Transaction.create }
              before { statement.transaction = transaction; statement.save }

              it 'includes link to account' do
                get "#{account.iban}/statements", { 'Authorization' => 'token orga-user' }
                expect_json '0._links.transaction', "http://localhost:5000/#{account.iban}/transactions/#{transaction.id}"
              end
            end

            context 'not linked to a transaction' do
              it 'includes link to account' do
                get "#{account.iban}/statements", { 'Authorization' => 'token orga-user' }
                expect_json '0._links.transaction', nil
              end
            end
          end

          it 'passes page and per_page params to statement retrieval function' do
            allow(Statement).to receive(:paginated_by_account) { double(all: [])}
            get "#{account.iban}/statements?page=4&per_page=2", { 'Authorization' => 'token orga-user' }
            expect(Statement).to have_received(:paginated_by_account).with(account.id, per_page: 2, page: 4)
          end

          it 'allows to filter results by a date range'
        end
      end
    end
  end
end
