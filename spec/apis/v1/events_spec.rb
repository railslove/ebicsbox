require 'spec_helper'

require_relative '../../../box/apis/v1/content'

module Box
  RSpec.describe Apis::V1::Content do
    let(:organization) { Fabricate(:organization) }
    let(:account) { organization.add_account(name: 'Test') }
    let!(:event) { account.add_event(type: 'test') }
    let!(:webhook_delivery) { event.add_webhook_delivery({}) }
    let!(:user) { User.create(organization_id: organization.id, name: 'Some user', access_token: 'orga-user') }

    describe 'GET /events' do
      context "without valid access_token" do
        it 'returns a 401' do
          get 'events'
          expect_status 401
        end
      end

      context "with valid access_token" do
        it 'returns an OK status' do
          get "events", { 'Authorization' => "token #{user.access_token}" }
          expect_status 200
        end

        it 'returns a list of events' do
          get "events", { 'Authorization' => "token #{user.access_token}" }
          expect_json_types :array
        end

        it 'exposes each events public id' do
          get "events", { 'Authorization' => "token #{user.access_token}" }
          expect_json '0.id', event.public_id
        end

        it 'references the endpoint to fetch more details' do
          get "events", { 'Authorization' => "token #{user.access_token}" }
          expect_json '0._links.self', regex(%r[http://localhost:5000/events/#{TestHelpers::UUID_REGEXP}])
        end
      end
    end

    describe 'GET /events/:id' do
      context "without valid access_token" do
        it 'returns a 401' do
          get "events/#{event.public_id}"
          expect_status 401
        end
      end

      context "with valid access_token" do
        it 'returns an OK status' do
          get "events/#{event.public_id}", { 'Authorization' => "token #{user.access_token}" }
          expect_status 200
        end

        it 'exposes each events public id' do
          get "events/#{event.public_id}", { 'Authorization' => "token #{user.access_token}" }
          expect_json 'id', event.public_id
        end

        it 'includes a list of all webhook delivery attempts' do
          get "events/#{event.public_id}", { 'Authorization' => "token #{user.access_token}" }
          expect_json_types webhook_deliveries: :array
        end
      end
    end
  end
end
