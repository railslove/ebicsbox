require 'spec_helper'

module Box
  RSpec.describe Apis::V2::Management do
    include_context 'admin user'

    let(:other_organization) { Fabricate(:organization) }

    describe 'GET /accounts/:iban/subscribers' do
      let(:account) { Account.create(name: 'name', iban: 'iban', bic: 'bic', organization_id: organization.id) }

      context 'without subscribers' do
        it 'returns an empty array' do
          get "management/accounts/#{account.iban}/subscribers", TestHelpers::VALID_HEADERS
          expect_json []
        end
      end

      context 'with subscribers' do
        before { account.add_subscriber(user_id: user.id, remote_user_id: 'test') }

        it 'returns a representation of account subscribers' do
          get "management/accounts/#{account.iban}/subscribers", TestHelpers::VALID_HEADERS
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
        post "management/accounts/#{account.iban}/subscribers", data, TestHelpers::VALID_HEADERS
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

        it 'returns a success code' do
          perform_request
          expect_status 201
        end

        it 'returns a representation of the subscriber' do
          perform_request
          expect_json 'ebics_user', 'test'
        end
      end
    end

    describe 'GET /accounts/:iban/subscribers/ini_letter' do
      let(:account) { Account.create(name: 'name', iban: 'iban', organization_id: organization.id) }

      def perform_request
        get "management/accounts/#{account.iban}/subscribers/#{subscriber.id}/ini_letter", TestHelpers::VALID_HEADERS
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
  end
end
