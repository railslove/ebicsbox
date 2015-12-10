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

      describe 'GET: /:account' do
        context 'without a valid user session' do
          it 'should fail'
        end

        context 'with valid user session' do
          include_context 'valid user'

          context 'account does not exist' do
            it 'fails with a proper error message' do
              get 'accounts/NOT_EXISTING', { 'Authorization' => "token #{user.access_token}" }
              expect_json 'message', 'Your organization does not have an account with given IBAN!'
            end

            it 'returns a 404' do
              get 'accounts/NOT_EXISTING', { 'Authorization' => "token #{user.access_token}" }
              expect_status 404
            end
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

      describe 'GET :account/transactions' do
        before { user }

        context 'account does not exist' do
          it 'returns a not found status' do
            get "NOT_EXISTING/transactions", { 'Authorization' => "token #{user.access_token}" }
            expect_status 404
          end

          it 'returns a proper error message' do
            get "NOT_EXISTING/transactions", { 'Authorization' => "token #{user.access_token}" }
            expect_json 'message', 'Your organization does not have an account with given IBAN!'
          end
        end

        context 'account owned by another organization' do
          let(:account) { other_organization.add_account(iban: SecureRandom.uuid) }

          it 'returns a not found status' do
            get "#{account.iban}/transactions", { 'Authorization' => "token #{user.access_token}" }
            expect_status 404
          end

          it 'returns a proper error message' do
            get "#{account.iban}/transactions", { 'Authorization' => "token #{user.access_token}" }
            expect_json 'message', 'Your organization does not have an account with given IBAN!'
          end
        end

        context 'account is owned by user\s organization' do
          let(:account) { organization.add_account(iban: SecureRandom.uuid) }

          it 'returns an empty array for new accounts' do
            get "#{account.iban}/transactions", { 'Authorization' => 'token orga-user' }
            expect_json([])
          end

          it 'returns properly formatted transactions'

          it 'allows to filter results by a date range'
        end
      end

      describe 'POST /:account/debits' do
        include_context 'valid user'

        let(:valid_payload) { {
          name: 'Some person',
          amount: 123,
          bic: 'DABAIE2D',
          iban: 'AL90208110080000001039531801',
          eref: SecureRandom.hex,
          mandate_id: '1123',
          mandate_signature_date: Time.now.to_i
        }}

        context 'account does not exist' do
          it 'fails with a proper error message' do
            post "NOT_EXISTING/debits", valid_payload, { 'Authorization' => "token #{user.access_token}" }
            expect_json 'message', 'Your organization does not have an account with given IBAN!'
          end

          it 'fails with a 404 status' do
            post "NOT_EXISTING/debits", valid_payload, { 'Authorization' => "token #{user.access_token}" }
            expect_status 404
          end
        end

        context 'account is owned by another organization' do
          let(:account) { other_organization.add_account(iban: 'SOME_IBAN') }

          it 'fails with a proper error message' do
            post "#{account.iban}/debits", valid_payload, { 'Authorization' => "token #{user.access_token}" }
            expect_json 'message', 'Your organization does not have an account with given IBAN!'
          end

          it 'fails with a 404 status' do
            post "#{account.iban}/debits", valid_payload, { 'Authorization' => "token #{user.access_token}" }
            expect_status 404
          end
        end

        context 'account is not yet activated' do
          let(:account) { organization.add_account(iban: 'AL90208110080000001039531801', name: 'Test Account', creditor_identifier: 'DE98ZZZ09999999999') }

          it 'fails with a proper error message' do
            post "#{account.iban}/debits", valid_payload, { 'Authorization' => "token #{user.access_token}" }
            expect_json 'message', 'The account has not been activated. Please activate before submitting requests!'
          end

          it 'fails with a 412 (precondition failed) status' do
            post "#{account.iban}/debits", valid_payload, { 'Authorization' => "token #{user.access_token}" }
            expect_status 412
          end
        end

        context 'account is activated and accessible' do
          let(:account) { organization.add_account(iban: 'AL90208110080000001039531801', name: 'Test Account', creditor_identifier: 'DE98ZZZ09999999999') }

          before { account.add_subscriber(activated_at: 1.day.ago) }

          context 'invalid data' do
            it 'includes a proper error message' do
              post "#{account.iban}/debits", { some: 'data' }, { 'Authorization' => "token #{user.access_token}" }
              expect_json 'message', 'Validation of your request\'s payload failed!'
            end

            it 'includes a list of all errors' do
              post "#{account.iban}/debits", { some: 'data' }, { 'Authorization' => "token #{user.access_token}" }
              expect_json_types errors: :object
            end
          end

          context 'valid data' do
            it 'iniates a new direct debit' do
              expect(Epics::Box::DirectDebit).to receive(:create!)
              post "#{account.iban}/debits", valid_payload, { 'Authorization' => "token #{user.access_token}" }
            end

            it 'returns a proper message' do
              post "#{account.iban}/debits", valid_payload, { 'Authorization' => "token #{user.access_token}" }
              expect_json 'message', 'Direct debit has been initiated successfully!'
            end

            it 'sets a default value for requested_date' do
              now = Time.now
              Timecop.freeze(now) do
                default = now.to_i + 172800
                expect(Epics::Box::DirectDebit).to receive(:create!).with(anything, hash_including('requested_date' => default), anything)
                post "#{account.iban}/debits", valid_payload, { 'Authorization' => "token #{user.access_token}" }
              end
            end
          end
        end
      end

      describe 'POST /:account/credits' do
        include_context 'valid user'

        let(:valid_payload) { {
          name: 'Some person',
          amount: 123,
          bic: 'DABAIE2D',
          iban: 'AL90208110080000001039531801',
          eref: SecureRandom.hex,
          remittance_information: 'Just s abasic test credit'
        }}

        context 'account does not exist' do
          it 'fails with a proper error message' do
            post "NOT_EXISTING/credits", valid_payload, { 'Authorization' => "token #{user.access_token}" }
            expect_json 'message', 'Your organization does not have an account with given IBAN!'
          end

          it 'fails with a 404 status' do
            post "NOT_EXISTING/credits", valid_payload, { 'Authorization' => "token #{user.access_token}" }
            expect_status 404
          end
        end

        context 'account is owned by another organization' do
          let(:account) { other_organization.add_account(iban: 'SOME_IBAN') }

          it 'fails with a proper error message' do
            post "#{account.iban}/credits", valid_payload, { 'Authorization' => "token #{user.access_token}" }
            expect_json 'message', 'Your organization does not have an account with given IBAN!'
          end

          it 'fails with a 404 status' do
            post "#{account.iban}/credits", valid_payload, { 'Authorization' => "token #{user.access_token}" }
            expect_status 404
          end
        end

        context 'account is not yet activated' do
          let(:account) { organization.add_account(iban: 'AL90208110080000001039531801', name: 'Test Account', creditor_identifier: 'DE98ZZZ09999999999') }

          it 'fails with a proper error message' do
            post "#{account.iban}/credits", valid_payload, { 'Authorization' => "token #{user.access_token}" }
            expect_json 'message', 'The account has not been activated. Please activate before submitting requests!'
          end

          it 'fails with a 412 (precondition failed) status' do
            post "#{account.iban}/credits", valid_payload, { 'Authorization' => "token #{user.access_token}" }
            expect_status 412
          end
        end

        context 'account is activated and accessible' do
          let(:account) { organization.add_account(iban: 'AL90208110080000001039531801', name: 'Test Account', creditor_identifier: 'DE98ZZZ09999999999') }

          before { account.add_subscriber(activated_at: 1.day.ago) }

          context 'invalid data' do
            it 'includes a proper error message' do
              post "#{account.iban}/credits", { some: 'data' }, { 'Authorization' => "token #{user.access_token}" }
              expect_json 'message', 'Validation of your request\'s payload failed!'
            end

            it 'includes a list of all errors' do
              post "#{account.iban}/credits", { some: 'data' }, { 'Authorization' => "token #{user.access_token}" }
              expect_json_types errors: :object
            end
          end

          context 'valid data' do
            it 'iniates a new credit' do
              expect(Epics::Box::Credit).to receive(:create!)
              post "#{account.iban}/credits", valid_payload, { 'Authorization' => "token #{user.access_token}" }
            end

            it 'returns a proper message' do
              post "#{account.iban}/credits", valid_payload, { 'Authorization' => "token #{user.access_token}" }
              expect_json 'message', 'Credit has been initiated successfully!'
            end

            it 'sets a default value for requested_date' do
              now = Time.now
              Timecop.freeze(now) do
                default = now.to_i
                expect(Epics::Box::Credit).to receive(:create!).with(anything, hash_including('requested_date' => default), anything)
                post "#{account.iban}/credits", valid_payload, { 'Authorization' => "token #{user.access_token}" }
              end
            end
          end
        end
      end
    end
  end
end
