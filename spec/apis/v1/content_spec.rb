# frozen_string_literal: true

require 'active_support/all'
require 'spec_helper'

require_relative '../../../box/apis/v1/content'

module Box
  module Apis
    RSpec.describe V1::Content do
      let(:organization) { Fabricate(:organization) }
      let(:other_organization) { Fabricate(:organization) }
      let(:user) { User.create(organization_id: organization.id, name: 'Some user', access_token: 'orga-user') }

      describe 'Access' do
        context 'Unauthorized user' do
          it 'returns a 401 unauthorized code' do
            get '/'
            expect_status 401
          end

          it 'includes an error message' do
            get '/'
            expect_json 'message', 'Unauthorized access. Please provide a valid access token!'
          end
        end

        context 'authenticated user' do
          before { user }

          it 'grants access to the app' do
            get '/', 'Authorization' => 'token orga-user'
            expect_status 200
          end
        end
      end

      describe 'GET: /accounts' do
        it 'is not accessible for unknown users' do
          get '/accounts', 'Authorization' => nil
          expect_status 401
        end

        context 'valid user' do
          include_context 'valid user'

          it 'returns a success status' do
            get '/accounts', 'Authorization' => "token #{user.access_token}"
            expect_status 200
          end
        end
      end

      describe 'GET: /:account' do
        context 'without a valid user session' do
          it 'is not accessible for unknown users' do
            get '/accounts', 'Authorization' => nil
            expect_status 401
          end
        end

        context 'with valid user session' do
          include_context 'valid user'

          context 'account does not exist' do
            it 'fails with a proper error message' do
              get 'NOT_EXISTING', 'Authorization' => "token #{user.access_token}"
              expect_json 'message', 'Your organization does not have an account with given IBAN!'
            end

            it 'returns a 404' do
              get 'NOT_EXISTING', 'Authorization' => "token #{user.access_token}"
              expect_status 404
            end
          end

          context 'account exists' do
            let(:account) { organization.add_account(iban: 'AL90208110080000001039531801', name: 'Test Account', creditor_identifier: 'DE98ZZZ09999999999', balance_date: Date.new(2015, 1, 1), balance_in_cents: 123) }

            it 'includes current balance' do
              get account.iban, 'Authorization' => "token #{user.access_token}"
              expect_json 'balance_in_cents', 123
            end

            it 'includes balance date' do
              get account.iban, 'Authorization' => "token #{user.access_token}"
              expect_json 'balance_date', '2015-01-01'
            end
          end
        end
      end

      describe 'POST /:account/debits' do
        include_context 'valid user'

        let(:valid_payload) do
          {
            name: 'Some person',
            amount: 123,
            bic: 'DABAIE2D',
            iban: 'AL90208110080000001039531801',
            eref: SecureRandom.hex,
            mandate_id: '1123',
            mandate_signature_date: Time.now.to_i
          }
        end

        context 'account does not exist' do
          it 'fails with a proper error message' do
            post 'NOT_EXISTING/debits', valid_payload, 'Authorization' => "token #{user.access_token}"
            expect_json 'message', 'Your organization does not have an account with given IBAN!'
          end

          it 'fails with a 404 status' do
            post 'NOT_EXISTING/debits', valid_payload, 'Authorization' => "token #{user.access_token}"
            expect_status 404
          end
        end

        context 'account is owned by another organization' do
          let(:account) { other_organization.add_account(iban: 'SOME_IBAN', bic: 'SOME_BIC') }

          it 'fails with a proper error message' do
            post "#{account.iban}/debits", valid_payload, 'Authorization' => "token #{user.access_token}"
            expect_json 'message', 'Your organization does not have an account with given IBAN!'
          end

          it 'fails with a 404 status' do
            post "#{account.iban}/debits", valid_payload, 'Authorization' => "token #{user.access_token}"
            expect_status 404
          end
        end

        context 'account is not yet activated' do
          let(:account) { organization.add_account(iban: 'AL90208110080000001039531801', name: 'Test Account', creditor_identifier: 'DE98ZZZ09999999999', bic: 'SOME_BIC') }

          it 'fails with a proper error message' do
            post "#{account.iban}/debits", valid_payload, 'Authorization' => "token #{user.access_token}"
            expect_json 'message', 'The account has not been activated. Please activate before submitting requests!'
          end

          it 'fails with a 412 (precondition failed) status' do
            post "#{account.iban}/debits", valid_payload, 'Authorization' => "token #{user.access_token}"
            expect_status 412
          end
        end

        context 'account is activated and accessible' do
          let(:account) { organization.add_account(iban: 'AL90208110080000001039531801', name: 'Test Account', creditor_identifier: 'DE98ZZZ09999999999') }

          before { account.add_ebics_user(activated_at: 1.day.ago) }

          context 'invalid data' do
            it 'includes a proper error message' do
              post "#{account.iban}/debits", { some: 'data' }, 'Authorization' => "token #{user.access_token}"
              expect_json 'message', 'Validation of your request\'s payload failed!'
            end

            it 'includes a list of all errors' do
              post "#{account.iban}/debits", { some: 'data' }, 'Authorization' => "token #{user.access_token}"
              expect_json_types errors: :object
            end
          end

          context 'valid data' do
            it 'iniates a new direct debit' do
              expect(DirectDebit).to receive(:create!)
              post "#{account.iban}/debits", valid_payload, 'Authorization' => "token #{user.access_token}"
            end

            it 'does not send unknow attributes to business process' do
              allow(DirectDebit).to receive(:create!) do |_account, params, _user|
                expect(params).to_not include('testme')
              end
              post "#{account.iban}/debits", valid_payload.merge(testme: 'testme'), 'Authorization' => "token #{user.access_token}"
            end

            it 'returns a proper message' do
              post "#{account.iban}/debits", valid_payload, 'Authorization' => "token #{user.access_token}"
              expect_json 'message', 'Direct debit has been initiated successfully!'
            end

            it 'sets a default value for requested_date' do
              now = Time.now
              Timecop.freeze(now) do
                default = now.to_i + 172_800
                expect(DirectDebit).to receive(:create!).with(anything, hash_including('requested_date' => default), anything)
                post "#{account.iban}/debits", valid_payload, 'Authorization' => "token #{user.access_token}"
              end
            end
          end
        end
      end

      describe 'POST /:account/credits' do
        include_context 'valid user'

        let(:valid_payload) do
          {
            name: 'Some person',
            amount: 123,
            bic: 'DABAIE2D',
            iban: 'AL90208110080000001039531801',
            eref: SecureRandom.hex,
            remittance_information: 'Just s abasic test credit'
          }
        end

        let(:bicless_payload) do
          {
            name: 'Some person',
            amount: 123,
            iban: 'AL90208110080000001039531801',
            bic: '',
            eref: SecureRandom.hex,
            remittance_information: 'Just s abasic test credit'
          }
        end

        context 'account does not exist' do
          it 'fails with a proper error message' do
            post 'NOT_EXISTING/credits', valid_payload, 'Authorization' => "token #{user.access_token}"
            expect_json 'message', 'Your organization does not have an account with given IBAN!'
          end

          it 'fails with a 404 status' do
            post 'NOT_EXISTING/credits', valid_payload, 'Authorization' => "token #{user.access_token}"
            expect_status 404
          end
        end

        context 'account is owned by another organization' do
          let(:account) { other_organization.add_account(iban: 'SOME_IBAN', bic: 'SOME_BIC') }

          it 'fails with a proper error message' do
            post "#{account.iban}/credits", valid_payload, 'Authorization' => "token #{user.access_token}"
            expect_json 'message', 'Your organization does not have an account with given IBAN!'
          end

          it 'fails with a 404 status' do
            post "#{account.iban}/credits", valid_payload, 'Authorization' => "token #{user.access_token}"
            expect_status 404
          end
        end

        context 'account is not yet activated' do
          let(:account) { organization.add_account(iban: 'AL90208110080000001039531801', name: 'Test Account', creditor_identifier: 'DE98ZZZ09999999999', bic: 'DABAIE2D') }

          it 'fails with a proper error message' do
            post "#{account.iban}/credits", valid_payload, 'Authorization' => "token #{user.access_token}"
            expect_json 'message', 'The account has not been activated. Please activate before submitting requests!'
          end

          it 'fails with a 412 (precondition failed) status' do
            post "#{account.iban}/credits", valid_payload, 'Authorization' => "token #{user.access_token}"
            expect_status 412
          end
        end

        context 'account is activated and accessible' do
          let(:account) { organization.add_account(iban: 'AL90208110080000001039531801', name: 'Test Account', creditor_identifier: 'DE98ZZZ09999999999', bic: 'DABAIE2D') }

          before { account.add_ebics_user(activated_at: 1.day.ago) }

          context 'invalid data' do
            it 'includes a proper error message' do
              post "#{account.iban}/credits", { some: 'data' }, 'Authorization' => "token #{user.access_token}"
              expect_json 'message', 'Validation of your request\'s payload failed!'
            end

            it 'includes a list of all errors' do
              post "#{account.iban}/credits", { some: 'data' }, 'Authorization' => "token #{user.access_token}"
              expect_json_types errors: :object
            end

            it 'returns a proper error message with empty bic in payload' do
              post "#{account.iban}/credits", bicless_payload, 'Authorization' => "token #{user.access_token}"
              expect_json 'message', 'Validation of your request\'s payload failed!'
            end
          end

          context 'valid data' do
            it 'iniates a new credit' do
              expect(Box::Credit).to receive(:create!)
              post "#{account.iban}/credits", valid_payload, 'Authorization' => "token #{user.access_token}"
            end

            it 'returns a proper message' do
              post "#{account.iban}/credits", valid_payload, 'Authorization' => "token #{user.access_token}"
              expect_json 'message', 'Credit has been initiated successfully!'
            end

            it 'returns a proper message without bic in payload' do
              post "#{account.iban}/credits", bicless_payload.reject { |k, _v| k.to_s == 'bic' }, 'Authorization' => "token #{user.access_token}"
              expect_json 'message', 'Credit has been initiated successfully!'
            end

            it 'does not send unknow attributes to business process' do
              allow(Credit).to receive(:create!) do |_account, params, _user|
                expect(params).to_not include('testme')
              end
              post "#{account.iban}/credits", valid_payload.merge(testme: 'testme'), 'Authorization' => "token #{user.access_token}"
            end

            it 'sets a default value for requested_date' do
              now = Time.now
              Timecop.freeze(now) do
                default = now.to_i
                expect(Box::Credit).to receive(:create!).with(anything, hash_including('requested_date' => default), anything)
                post "#{account.iban}/credits", valid_payload, 'Authorization' => "token #{user.access_token}"
              end
            end
          end
        end
      end

      describe 'GET /:account/import/statements' do
        let(:account) do
          organization.add_account(
            iban: 'AL90208110080000001039531801',
            bic: 'DABAIE2D',
            name: 'Test Account',
            creditor_identifier: 'DE98ZZZ09999999999',
            balance_date: Date.new(2015, 1, 1),
            balance_in_cents: 123
          )
        end
        let(:from) { 30.days.ago.to_date }
        let(:to) { Date.today }

        it 'is not accessible for unknown users' do
          get "/#{account.iban}/import/statements", 'Authorization' => nil
          expect_status 401
        end

        context 'valid user' do
          include_context 'valid user'

          let(:job_double) { double('Jobs::FetchStatements') }

          before(:each) do
            allow(Jobs::FetchStatements).to receive(:new).and_return(job_double)
            allow(job_double).to receive(:perform).and_return(total: 12, imported: 3)

            account.add_ebics_user(activated_at: 1.day.ago)

            get "/#{account.iban}/import/statements?from=#{from}&to=#{to}", 'Authorization' => "token #{user.access_token}"
          end

          it 'returns a success status' do
            expect_status 200
          end

          it 'calls statement fetching' do
            expect(job_double).to have_received(:perform).with(account.id, from: from, to: to)
          end

          it 'returns import stats' do
            expect_json fetched: 12, imported: 3, message: 'Imported statements successfully'
          end
        end
      end
    end
  end
end
