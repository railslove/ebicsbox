# frozen_string_literal: true

require 'spec_helper'

require_relative '../../box/adapters/fake'
require_relative '../../box/models/account'

module Box
  module Adapters
    RSpec.describe Fake do
      let!(:organization) { Fabricate(:organization) }
      let!(:account) { organization.add_account(iban: 'AL90208110080000001039531801', name: 'Test account', mode: 'Fake', url: 'url', host: 'host', partner: 'partner', creditor_identifier: 'DE98ZZZ09999999999') }
      let!(:user) { organization.add_user(name: 'Test user') }
      let!(:ebics_user) { account.add_ebics_user(user_id: user.id, signature_class: 'T', activated_at: 1.day.ago) }

      around do |example|
        Sidekiq::Testing.inline! do
          example.run
        end
      end

      describe 'Account setup' do
        let(:ebics_user) { account.add_ebics_user(user_id: user.id, remote_user_id: 'TEST') }

        it 'allows to setup a ebics_user' do
          expect { ebics_user.setup!(account) }.to(change { ebics_user.reload.submitted_at })
        end

        it 'allows to activate a ebics_user' do
          expect { ebics_user.activate! }.to(change { ebics_user.reload.activated_at })
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
            remittance_information: 'Just a basic test credit',
            requested_date: Time.now.to_i
          }
        end

        before do
          expect(Queue).to receive(:update_processing_status).and_return(true) # we don't want to run this job
        end

        context 'auto accept any credits and create statements' do
          let(:run_job) { Credit.create!(account, valid_payload.merge(amount: 100_00), user) }
          before do
            Sidekiq::Testing.inline!
          end

          it 'creates a statement entry' do
            expect { run_job }.to(change(Statement, :count))
          end

          it 'marks the transaction as being processed successfully' do
            run_job
            expect(Transaction.last.status).to eq('funds_debited')
          end

          it 'creates a credit statement' do
            run_job
            expect(Statement.last.debit).to be_falsey
          end

          it 'creates associated events' do
            expect { run_job }.to(change { Event.all.map(&:type).sort }.to(%w[credit_created credit_status_changed statement_created]))
          end
        end

        context 'amounts' do
          let(:run_job) { Credit.create!(account, valid_payload.merge(amount: 251_995), user) }

          it 'sets correct statement account' do
            run_job
            expect(Statement.last.amount).to eq(251_995)
          end
        end
      end

      describe 'Debit an account' do
        let(:valid_payload) do
          {
            name: 'Some person',
            bic: 'DABAIE2D',
            iban: 'AL90208110080000001039531801',
            amount: 123,
            eref: SecureRandom.hex,
            mandate_id: SecureRandom.hex,
            mandate_signature_date: Time.now.to_i,
            requested_date: 2.days.from_now,
            remittance_information: 'Just a basic test direct debit',
            instrument: 'CORE'
          }
        end

        before do
          expect(Queue).to receive(:update_processing_status).and_return(true) # we don't want to run this job
        end

        context 'auto accept any direct debits and create statements' do
          let(:run_job) { DirectDebit.create!(account, valid_payload.merge(amount: 100_00), user) }
          before do
            Sidekiq::Testing.inline!
          end

          it 'creates a statement entry' do
            expect { run_job }.to(change(Statement, :count))
          end

          it 'marks the transaction as being processed successfully' do
            run_job
            expect(Transaction.last.status).to eq('funds_credited')
          end

          it 'creates a debit statement' do
            run_job
            expect(Statement.last.debit).to be_truthy
          end

          it 'contains correct info' do
            run_job
            expect(Statement.last.description).to eq('Just a basic test direct debit')
          end

          it 'creates associated events' do
            expect { run_job }.to(change { Event.all.map(&:type).sort }.to(%w[debit_created debit_status_changed statement_created]))
          end
        end

        context 'amounts' do
          let(:run_job) { DirectDebit.create!(account, valid_payload.merge(amount: 251_995), user) }

          it 'sets correct statement account' do
            run_job
            expect(Statement.last.amount).to eq(251_995)
          end
        end
      end
    end
  end
end
