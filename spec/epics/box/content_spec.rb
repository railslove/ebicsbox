module Epics
  module Box
    RSpec.describe Content do
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

      describe "GET: /accounts" do
        it 'is not accessible for unknown users' do
          get '/accounts', { 'Authorization' => nil }
          expect_status 401
        end

        context 'valid user' do
          include_context 'valid user'

          it 'returns a success status' do
            get '/accounts', { 'Authorization' => "token #{user.access_token}" }
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
    end
  end
end
