# frozen_string_literal: true

require 'spec_helper'

module Box
  RSpec.describe Apis::V2::Management::Users do
    include_context 'admin user'

    let(:other_organization) { Fabricate(:organization) }

    describe 'GET /management/users' do
      before { organization.add_user(name: 'Test User', access_token: 'secret') }

      def perform_request(_data = {})
        get 'management/users', TestHelpers::VALID_HEADERS
      end

      it "does not include the user's access token" do
        perform_request
        expect_json_types '0.access_token', :null
      end
    end

    describe 'POST /management/users' do
      def perform_request(data = {})
        post 'management/users', { name: 'Another Test User' }.merge(data), TestHelpers::VALID_HEADERS
      end

      it 'creates a new user for the organization' do
        expect { perform_request }.to change(User, :count).by(1)
      end

      it 'auto generates an access token if none is provided' do
        perform_request(token: nil)
        expect_json_types 'access_token', :string
      end

      it 'uses the provided access token' do
        perform_request(token: 'secret')
        expect_json 'access_token', 'secret'
      end
    end

    describe 'DELETE /management/users/:id' do
      let!(:user_to_delete) { Fabricate(:user) }

      it 'deletes an existing user' do
        expect { delete("management/users/#{user_to_delete.id}", {}, TestHelpers::VALID_HEADERS) }.to(
          change { Box::User.count }.by(-1)
        )
      end

      it 'deletes an existing user' do
        delete("management/users/#{user_to_delete.id}", {}, TestHelpers::VALID_HEADERS)
        expect(Box::User[user_to_delete.id]).to be_nil
      end

      it 'deletes an existing user' do
        delete("management/users/#{user_to_delete.id}", {}, TestHelpers::VALID_HEADERS)
        expect(response.status).to eql(204)
      end

      it 'raises a 404 if user not found' do
        delete 'management/users/-1', {}, TestHelpers::VALID_HEADERS
        expect(response.status).to eql(404)
      end
    end
  end
end
