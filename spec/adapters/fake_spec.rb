# frozen_string_literal: true

require 'spec_helper'
require 'clockwork'

require_relative '../../box/adapters/fake'
require_relative '../../box/models/account'

module Box
  module Adapters
    RSpec.describe Fake do
      let!(:organization) { Fabricate(:organization) }
      let!(:account) { organization.add_account(iban: 'AL90208110080000001039531801', name: 'Test account', mode: 'Fake', url: 'url', host: 'host', partner: 'partner') }
      let!(:user) { organization.add_user(name: 'Test user') }
      let!(:subscriber) { account.add_subscriber(user_id: user.id, signature_class: 'T', activated_at: 1.day.ago) }

      before(:each) { Sidekiq::Queue.all.each(&:clear) }

      describe 'Account setup' do
        let(:subscriber) { account.add_subscriber(user_id: user.id, remote_user_id: 'TEST') }

        it 'allows to setup a subscriber' do
          expect { subscriber.setup! }.to change { subscriber.reload.submitted_at }
        end

        it 'allows to activate a subscriber' do
          expect { subscriber.activate! }.to change { subscriber.reload.activated_at }
        end
      end

      describe 'Credit an account' do
        let(:valid_payload) do
          {
            name: 'Some person',
            amount: 123,
            bic: 'DABAIE2D',
            iban: 'AL90208110080000001039531801',
            eref: SecureRandom.hex,
            remittance_information: 'Just s abasic test credit',
            requested_date: Time.now.to_i
          }
        end

        context 'auto accept any credits and create statements' do
          before do
            jid = Credit.create!(account, valid_payload.merge(amount: 100_00), user)
            @job = Sidekiq::Queue.new('credit').find { |j| j.jid == jid }
          end

          it 'creates a statement entry' do
            expect { Jobs::Credit.new.perform(@job.args.first) }.to change { Statement.count }
          end

          it 'marks the transaction as being processed successfully' do
            Jobs::Credit.new.perform(@job.args.first)
            expect(Transaction.last.status).to eq('funds_debited')
          end

          it 'creates associated events' do
            expect { Jobs::Credit.new.perform(@job.args.first) }.to change { Event.all.map(&:type).sort }.to(%w[credit_created credit_status_changed statement_created])
          end
        end

        context 'amounts' do
          before do
            jid = Credit.create!(account, valid_payload.merge(amount: 251_995), user)
            @job = Sidekiq::Queue.new('credit').find { |j| j.jid == jid }
          end

          it 'sets correct statement account' do
            Jobs::Credit.new.perform(@job.args.first)
            expect(Statement.last.amount).to eq(251_995)
          end
        end
      end
    end
  end
end
