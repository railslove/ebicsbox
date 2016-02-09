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
            get "#{account.iban}/statements?test=1", { 'Authorization' => "token #{user.access_token}" }
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
            let!(:statement) { Statement.create account_id: account.id, swift_code: 'NTRF', raw_data: 'RAW' }

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

            context 'raw mt940' do
              it 'includes raw mt940' do
                get "#{account.iban}/statements", { 'raw_data' => true, 'Authorization' => 'token orga-user' }
                expect_json '0.mt940', "RAW"
              end

              it 'does not include raw mt940 on default' do
                get "#{account.iban}/statements", { 'Authorization' => 'token orga-user' }
                expect_json '0.mt940', nil
              end
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

          describe 'filtering by transaction id' do
            let(:trx_1) { Transaction.create }
            let(:trx_2) { Transaction.create }
            let!(:statement_1) { Statement.create account_id: account.id, transaction_id: trx_1.id, eref: 'trx-1' }
            let!(:statement_2) { Statement.create account_id: account.id, transaction_id: trx_2.id, eref: 'trx-2' }

            it 'only includes statements which are linked to requested transaction' do
              get "#{account.iban}/statements?transaction_id=#{trx_1.id}", { 'Authorization' => 'token orga-user' }
              expect_json '*', eref: 'trx-1'
            end
          end

          describe 'filtering by date' do
            let!(:statement_1) { Statement.create account_id: account.id, eref: 'trx-1', date: '2015-12-01' }
            let!(:statement_2) { Statement.create account_id: account.id, eref: 'trx-2', date: '2015-12-02' }
            let!(:statement_3) { Statement.create account_id: account.id, eref: 'trx-3', date: '2015-12-03' }

            it 'only includes statements with date after or on from param' do
              get "#{account.iban}/statements?from=2015-12-03", { 'Authorization' => 'token orga-user' }
              expect_json '*', eref: 'trx-3'
            end

            it 'only includes statements with date before or on to param' do
              get "#{account.iban}/statements?to=2015-12-01", { 'Authorization' => 'token orga-user' }
              expect_json '*', eref: 'trx-1'
            end

            it 'includes all statements if no date filter param is provided' do
              get "#{account.iban}/statements", { 'Authorization' => 'token orga-user' }
              expect(json_body.map {|h| h[:eref] }).to match_array(["trx-3", "trx-2", "trx-1"])
            end
          end

          describe 'filtering by type' do
            let!(:statement_1) { Statement.create account_id: account.id, eref: 'trx-1', debit: true }
            let!(:statement_2) { Statement.create account_id: account.id, eref: 'trx-2', debit: false }

            it 'only includes credit statements' do
              get "#{account.iban}/statements?type=credit", { 'Authorization' => 'token orga-user' }
              expect_json '*', eref: 'trx-2'
            end

            it 'only includes debit statements' do
              get "#{account.iban}/statements?type=debit", { 'Authorization' => 'token orga-user' }
              expect_json '*', eref: 'trx-1'
            end

            it 'includes all statements if no type filter param is provided' do
              get "#{account.iban}/statements", { 'Authorization' => 'token orga-user' }
              expect(json_body.map {|h| h[:eref] }).to match_array(["trx-2", "trx-1"])
            end
          end

          it 'passes page and per_page params to statement retrieval function' do
            allow(Statement).to receive(:paginated_by_account) { double(all: [])}
            get "#{account.iban}/statements?page=4&per_page=2", { 'Authorization' => 'token orga-user' }
            expect(Statement).to have_received(:paginated_by_account).with(hash_including(account_id: account.id, per_page: 2, page: 4))
          end

          it 'allows to filter results by a date range'
        end
      end

      describe 'GET :account/import/statements' do
        let(:account) { organization.add_account(iban: SecureRandom.uuid) }
        let(:client) { double('Epics Client') }
        let!(:subscriber) { account.add_subscriber(signature_class: 'T', activated_at: 1.day.ago) }

        before { user }

        it 'works' do
          allow_any_instance_of(Subscriber).to receive(:client) { client }
          allow(client).to receive(:STA).and_return(File.read('spec/fixtures/mt940.txt'))
          get "#{account.iban}/import/statements?from=2015-12-01&to=2015-12-31", { 'Authorization' => 'token orga-user' }
          expect_json_types fetched: :integer, imported: :integer
        end
      end
    end
  end
end
