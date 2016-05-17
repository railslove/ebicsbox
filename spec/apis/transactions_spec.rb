require 'spec_helper'

require_relative '../../box/apis/content'

module Box
  module Apis
    RSpec.describe Content do
      let(:organization) { Organization.create(name: 'Organization 1') }
      let(:other_organization) { Organization.create(name: 'Organization 2') }
      let(:statement) { Statement.new }

      let!(:user) { User.create(organization_id: organization.id, name: 'Some user', access_token: 'orga-user') }

      describe 'GET :account/transactions' do

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
            expect(response.body).to eq('[]')
          end

          it 'returns properly formatted transactions'

          it 'allows to filter results by a date range'

          describe 'response' do
            let!(:statement) { Transaction.create account_id: account.id, type: 'credit' }

            it 'includes account IBAN' do
              get "#{account.iban}/transactions", { 'Authorization' => 'token orga-user' }
              expect_json '0.account', account.iban
            end

            it 'includes link to self' do
              get "#{account.iban}/transactions", { 'Authorization' => 'token orga-user' }
              expect_json '0._links.self', "http://localhost:5000/#{account.iban}/transactions/#{statement.id}"
            end

            it 'includes link to account' do
              get "#{account.iban}/transactions", { 'Authorization' => 'token orga-user' }
              expect_json '0._links.account', "http://localhost:5000/#{account.iban}"
            end

            it 'includes transaction type' do
              get "#{account.iban}/transactions", { 'Authorization' => 'token orga-user' }
              expect_json '0.type', "credit"
            end
          end
        end

      end
    end
  end
end
