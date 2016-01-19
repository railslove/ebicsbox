require 'spec_helper'
require 'clockwork'

require 'lib/epics/box/adapters/fake'
require 'lib/epics/box/models/account'

module Epics
  module Box
    module Adapters
      RSpec.describe Fake do
        let!(:organization) { Organization.create(name: "Test Orga") }
        let!(:account) { organization.add_account(iban: "AL90208110080000001039531801", name: "Test account", mode: 'Fake', url: 'url', host: 'host', partner: 'partner') }
        let!(:user) { organization.add_user(name: "Test user", access_token: SecureRandom.hex) }
        let!(:subscriber) { account.add_subscriber(user_id: user.id, signature_class: 'T', activated_at: 1.day.ago) }

        describe 'Account setup' do
          let(:subscriber) { account.add_subscriber(user_id: user.id, remote_user_id: "TEST", ) }

          it 'allows to setup a subscriber' do
            expect{ subscriber.setup! }.to change { subscriber.reload.submitted_at }
          end

          it 'allows to activate a subscriber' do
            expect{ subscriber.activate! }.to change { subscriber.reload.activated_at }
          end
        end

        describe 'Credit an account' do
          let(:valid_payload) { {
            name: 'Some person',
            amount: 123,
            bic: 'DABAIE2D',
            iban: 'AL90208110080000001039531801',
            eref: SecureRandom.hex,
            remittance_information: 'Just s abasic test credit',
            requested_date: Time.now.to_i,
          }}

          before { Queue.clear!(Queue::CREDIT_TUBE) }

          context 'auto accept with an amount of 100 EUR' do
            before do
              Credit.create!(account, valid_payload.merge(amount: 100_00), user)
              @job = Queue.client.tubes[Queue::CREDIT_TUBE].reserve
            end

            it 'creates a statement entry' do
              expect { Jobs::Credit.process!(@job.body) }.to change { Statement.count }
            end

            it 'marks the transaction as being processed successfully' do
              Jobs::Credit.process!(@job.body)
              expect(Transaction.last.status).to eq('funds_debited')
            end

            it 'creates associated events' do
              expect { Jobs::Credit.process!(@job.body) }.to change { Event.all.map(&:type) }.to(["transaction_updated", "credit_created"])
            end
          end

          it 'rejects transactions with an amount of 200 EUR' do
            Credit.create!(account, valid_payload.merge(amount: 200_00), user)
            job = Queue.client.tubes[Queue::CREDIT_TUBE].reserve
            expect { Epics::Box::Jobs::Credit.process!(job.body) }.to_not change { Statement.count }
          end

          it 'does not process transactions with another amount' do
            Credit.create!(account, valid_payload.merge(amount: 300_00), user)
            job = Queue.client.tubes[Queue::CREDIT_TUBE].reserve
            expect { Epics::Box::Jobs::Credit.process!(job.body) }.to_not change { Statement.count }
          end
        end
      end
    end
  end
end
