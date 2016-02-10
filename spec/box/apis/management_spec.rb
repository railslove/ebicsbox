require 'active_support/all'

module Box
  module Apis
    RSpec.describe Management do
      let(:organization) { Organization.create(name: 'Organization 1', management_token: 'management-token-1') }
      let(:other_organization) { Organization.create(name: 'Organization 2', management_token: 'management-token-2') }
      let(:user) { User.create(organization_id: organization.id, name: 'Some user', access_token: 'orga-user') }

      describe 'Access' do
        context 'Unauthorized user' do
          it 'returns a 401 unauthorized code' do
            get "management/"
            expect_status 401
          end

          it 'includes an error message' do
            get "management/"
            expect_json 'message', 'Unauthorized access. Please provide a valid organization management token token!'
          end
        end

        context 'regular user token' do
          before { user }

          it 'returns a 401 unauthorized code' do
            get 'management/', { 'Authorization' => 'token orga-user' }
            expect_status 401
          end

          it 'includes an error message' do
            get "management/", { 'Authorization' => 'token orga-user' }
            expect_json 'message', 'Unauthorized access. Please provide a valid organization management token token!'
          end
        end

        context 'management token' do
          before { organization }

          it 'grants access to the app' do
            get 'management/', { 'Authorization' => 'token management-token-1' }
            expect_status 200
          end
        end
      end

      describe 'POST /accounts' do
        before { user }

        context 'invalid body' do
          before { post 'management/accounts', {}, { 'Authorization' => 'token management-token-1' } }

          it 'rejects empty posts' do
            expect_status 400
          end

          it 'contains a meaningful message' do
            expect_json 'message', "Validation of your request's payload failed!"
          end

          it 'highlights missing fields' do
            expect_json 'errors', {
              name: ["is missing", "is empty"],
              iban: ["is missing", "is empty"],
              bic: ["is missing", "is empty"],
            }
          end
        end

        context 'valid body' do
          def do_request
            post 'management/accounts', { name: 'Test account', iban: 'my-iban', bic: 'my-iban' }, { 'Authorization' => 'token management-token-1' }
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
        let(:other_account) { Account.create(name: 'name', iban: 'iban-2', bic: 'bic-2', organization_id: other_organization.id) }

        before { user }

        context 'no account with given IBAN exist' do
          it 'returns an error' do
            put "management/accounts/NOTEXISTING", {}, { 'Authorization' => 'token management-token-1' }
            expect_status 400
          end

          it 'returns a proper error message' do
            put "management/accounts/NOTEXISTING", {}, { 'Authorization' => 'token management-token-1' }
            expect_json 'message', 'Your organization does not have an account with given IBAN!'
          end
        end

        context 'account with given IBAN belongs to another organization' do
          it 'denies updates to inaccesible accounts' do
            put "management/accounts/#{other_account.iban}", {}, { 'Authorization' => 'token management-token-1' }
            expect_status 400
          end

          it 'returns a proper error message' do
            put "management/accounts/#{other_account.iban}", {}, { 'Authorization' => 'token management-token-1' }
            expect_json 'message', 'Your organization does not have an account with given IBAN!'
          end
        end

        context 'activated account' do
          before { account.add_subscriber(activated_at: 1.hour.ago) }

          it 'cannot change iban' do
            expect { put "management/accounts/#{account.iban}", { iban: 'new-iban' }, { 'Authorization' => 'token management-token-1' } }.to_not change { account.reload.iban }
          end

          it 'cannot change bic' do
            expect { put "management/accounts/#{account.iban}", { bic: 'new-bic' }, { 'Authorization' => 'token management-token-1' } }.to_not change { account.reload.bic }
          end

          it 'ignores iban if it did not change' do
            expect { put "management/accounts/#{account.iban}", { iban: 'old-iban', name: 'new name' }, { 'Authorization' => 'token management-token-1' } }.to change { account.reload.name }
          end
        end

        context 'inactive account' do
          before { account.subscribers_dataset.update(activated_at: nil) }

          it 'can change iban' do
            expect { put "management/accounts/#{account.iban}", { iban: 'new-iban' }, { 'Authorization' => 'token management-token-1' } }.to change { account.reload.iban }
          end

          it 'can change iban' do
            expect { put "management/accounts/#{account.iban}", { bic: 'new-bic' }, { 'Authorization' => 'token management-token-1' } }.to change { account.reload.bic }
          end
        end
      end

      describe 'GET /accounts/:iban/subscribers' do
        let(:account) { Account.create(name: 'name', iban: 'iban', bic: 'bic', organization_id: organization.id) }

        context 'without subscribers' do
          it 'returns an empty array' do
            get "management/accounts/#{account.iban}/subscribers", { 'Authorization' => 'token management-token-1' }
            expect_json []
          end
        end

        context 'with subscribers' do
          before { account.add_subscriber(user_id: user.id, remote_user_id: 'test') }

          it 'returns a representation of account subscribers' do
            get "management/accounts/#{account.iban}/subscribers", { 'Authorization' => 'token management-token-1' }
            expect_json '0.ebics_user', 'test'
          end
        end
      end

      describe 'POST /accounts/:iban/subscribers' do
        let(:account) { Account.create(
          name: 'name',
          iban: 'iban',
          bic: 'bic',
          url: 'url',
          host: 'host',
          partner: 'partner',
          mode: 'File',
          organization_id: organization.id) }

        def perform_request
          post "management/accounts/#{account.iban}/subscribers", data, { 'Authorization' => 'token management-token-1' }
        end

        context 'missing attributes' do
          let(:data) { { ebics_user: "test" } }

          it 'returns an error code' do
            perform_request
            expect_status 400
          end

          it 'contains a meaningful message' do
            perform_request
            expect_json 'message', "Validation of your request's payload failed!"
          end

          it 'highlights missing fields' do
            perform_request
            expect_json 'errors', user_id: ['is missing']
          end
        end

        context 'user with same used id' do
          let(:data) { { ebics_user: "test", user_id: user.id } }

          before { account.add_subscriber(remote_user_id: 'test', user_id: user.id) }

          it 'returns an error code' do
            perform_request
            expect_status 400
          end

          it 'contains a meaningful message' do
            perform_request
            expect_json 'message', "Validation of your request's payload failed!"
          end

          it 'highlights interfering fields' do
            perform_request
            expect_json 'errors', ebics_user: ['already setup for given account']
          end
        end

        context 'remote ebics server throws an error' do
          let(:data) { { ebics_user: "test", user_id: user.id } }

          before { allow_any_instance_of(Subscriber).to receive(:setup!).and_return(false) }

          it 'returns an error status' do
            perform_request
            expect_status 412
          end

          it 'returns a meaningful error message' do
            perform_request
            expect_json 'message', 'Failed to setup subscriber. Make sure your data is valid and retry!'
          end

          it 'removes created subscriber' do
            expect { perform_request }.to_not change { Subscriber.count }
          end
        end

        context 'valid data' do
          let(:data) { { ebics_user: "test", user_id: user.id } }

          # before { stub_request(:post, /url/).to_return(status: 200, body: '') }

          it 'returns a success code' do
            perform_request
            expect_status 201
          end

          it 'returns a meaningful message' do
            perform_request
            expect_json 'message', 'Subscriber has been created and setup successfully! Please fetch INI letter, sign it, and submit it to your bank.'
          end

          it 'returns a representation of the subscriber' do
            perform_request
            expect_json 'subscriber.ebics_user', 'test'
          end
        end
      end

      describe 'GET /accounts/:iban/subscribers/ini_letter' do
        let(:account) { Account.create(name: 'name', iban: 'iban', organization_id: organization.id) }

        def perform_request
          get "management/accounts/#{account.iban}/subscribers/#{subscriber.id}/ini_letter", { 'Authorization' => 'token management-token-1' }
        end

        context 'setup has not been performed' do
          let(:subscriber) { account.add_subscriber(remote_user_id: 'test1') }

          it 'fails with an error status' do
            perform_request
            expect_status 412
          end

          it 'fails with a meaningful error message' do
            perform_request
            expect_json 'message', 'Subscriber setup not yet initiated'
          end
        end

        context 'setup has been initiated before' do
          let(:subscriber) { account.add_subscriber(remote_user_id: "test1", ini_letter: "INI LETTER") }

          it 'returns a success code' do
            perform_request
            expect_status 200
          end

          it 'returns data as html content' do
            perform_request
            expect(response.headers["Content-Type"]).to eq('text/html')
          end

          it 'returns the ini letter' do
            perform_request
            expect(response.body).to eq("INI LETTER")
          end
        end
      end

      describe 'POST /management/users' do
        before { organization.add_user(name: 'Test User', access_token: 'secret') }

        def perform_request(data = {})
          get "management/users", { 'Authorization' => 'token management-token-1' }
        end

        it "does not include the user's access token" do
          perform_request
          expect_json_types '0.access_token', :null
        end
      end

      describe 'POST /management/users' do
        before { organization }

        def perform_request(data = {})
          post "management/users", { name: "Test user" }.merge(data), { 'Authorization' => 'token management-token-1' }
        end

        it 'creates a new user for the organization' do
          expect { perform_request }.to change { User.count }.by(1)
        end

        it 'auto generates an access token if none is provided' do
          perform_request(token: nil)
          expect_json_types 'user.access_token', :string
        end

        it 'uses the provided access token' do
          perform_request(token: 'secret')
          expect_json 'user.access_token', 'secret'
        end
      end
    end
  end
end
