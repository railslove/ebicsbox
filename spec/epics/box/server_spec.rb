module Epics
  module Box
    RSpec.describe Server do
      let(:organization) { Organization.create(name: 'Organization 1') }
      let(:other_organization) { Organization.create(name: 'Organization 2') }
      let(:user) { User.create(organization_id: organization.id, name: 'Some user', access_token: 'orga-user') }

      describe 'Access' do
        context 'Unauthorized user' do
          it 'returns a 401 unauthorized code' do
            get "/"
            expect_status 401
          end

          it 'includes an error message' do
            get "/"
            expect_json 'message', 'Unauthorized access. Please provide a valid access token!'
          end
        end

        context 'authenticated user' do
          before { user }

          it 'grants access to the app' do
            get '/', { 'Authorization' => 'token orga-user' }
            expect_status 200
          end
        end
      end

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
            expect_json([])
          end

          it 'returns properly formatted statements' do
            statement = Statement.create account_id: account.id
            get "#{account.iban}/statements", { 'Authorization' => 'token orga-user' }
            expect_json '0.statement', { account_id: account.id }
          end

          it 'passes page and per_page params to statement retrieval function' do
            allow(Statement).to receive(:paginated_by_account) { double(all: [])}
            get "#{account.iban}/statements?page=4&per_page=2", { 'Authorization' => 'token orga-user' }
            expect(Statement).to have_received(:paginated_by_account).with(account.id, per_page: 2, page: 4)
          end

          it 'allows to filter results by a date range'
        end
      end

      describe 'POST /accounts' do
        before { user }

        context 'invalid body' do
          before { post 'accounts', {}, { 'Authorization' => 'token orga-user' } }

          it 'rejects empty posts' do
            expect_status 400
          end

          it 'rejects empty posts' do
            expect_json_types error: :string
          end
        end

        context 'valid body' do
          def do_request
            post 'accounts', { name: 'Test account', iban: 'my-iban', bic: 'my-iban' }, { 'Authorization' => 'token orga-user' }
          end

          it 'stores new minimal accounts' do
            expect { do_request }.to change { Account.count }
          end

          it 'returns a 201 status' do
            do_request
            expect(response.status).to eq(201)
          end
        end
      end

      describe 'PUT /accounts/:id' do
        let(:account) { Account.create(name: 'name', iban: 'old-iban', bic: 'old-bic', organization_id: organization.id) }
        let(:other_account) { Account.create(name: 'name', iban: 'iban-2', bic: 'bic-2', organization_id: other_organization.id, activated_at: 1.hour.ago) }

        before { user }

        context 'no account with given IBAN exist' do
          it 'returns an error' do
            put "accounts/NOTEXISTING", {}, { 'Authorization' => 'token orga-user' }
            expect_status 400
          end

          it 'returns a proper error message' do
            put "accounts/NOTEXISTING", {}, { 'Authorization' => 'token orga-user' }
            expect_json 'message', 'Your organization does not have an account with given IBAN!'
          end
        end

        context 'account with given IBAN belongs to another organization' do
          it 'denies updates to inaccesible accounts' do
            put "accounts/#{other_account.iban}", {}, { 'Authorization' => 'token orga-user' }
            expect_status 400
          end

          it 'returns a proper error message' do
            put "accounts/#{other_account.iban}", {}, { 'Authorization' => 'token orga-user' }
            expect_json 'message', 'Your organization does not have an account with given IBAN!'
          end
        end

        context 'activated account' do
          before { account.update(activated_at: 1.hour.ago) }

          it 'cannot change iban' do
            expect { put "accounts/#{account.iban}", { iban: 'new-iban' }, { 'Authorization' => 'token orga-user' } }.to_not change { account.reload.iban }
          end

          it 'cannot change bic' do
            expect { put "accounts/#{account.iban}", { bic: 'new-bic' }, { 'Authorization' => 'token orga-user' } }.to_not change { account.reload.bic }
          end

          it 'ignores iban if it did not change' do
            expect { put "accounts/#{account.iban}", { iban: 'old-iban', name: 'new name' }, { 'Authorization' => 'token orga-user' } }.to change { account.reload.name }
          end
        end

        context 'inactive account' do
          before { account.update(activated_at: nil) }

          it 'can change iban' do
            expect { put "accounts/#{account.iban}", { iban: 'new-iban' }, { 'Authorization' => 'token orga-user' } }.to change { account.reload.iban }
          end

          it 'can change iban' do
            expect { put "accounts/#{account.iban}", { bic: 'new-bic' }, { 'Authorization' => 'token orga-user' } }.to change { account.reload.bic }
          end
        end
      end
    end
  end
end
