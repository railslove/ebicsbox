require 'active_support/all'
require 'cmxl'

require_relative '../../box/models/account'
require_relative '../../box/business_processes/import_bank_statement'

module Box
  module BusinessProcesses
    RSpec.describe ImportBankStatement do
      let(:account) { Account.create(host: "HOST", iban: "iban1234567") }
      let(:mt940_fixture) { 'single_valid.mt940' }
      let(:mt940) { File.read("spec/fixtures/#{mt940_fixture}") }

      describe '.from_mt940' do
        it 'calls from_cmxl with parsed data' do
          expect(described_class).to receive(:from_cmxl).with(an_instance_of(Cmxl::Statement), account)
          described_class.from_mt940(mt940, account)
        end
      end

      describe '.from_cmxl' do
        let(:cmxl) { Cmxl.parse(mt940).first }

        def import
          described_class.from_cmxl(cmxl, account)
        end

        describe 'input validation' do
          context 'invalid raw bank statement' do
            it 'fails with an error' do
              expect { described_class.from_cmxl(nil, account) }.to raise_error(ImportBankStatement::InvalidInput)
            end
          end

          context 'data for unknown sub-account' do
            let(:mt940_fixture) { 'single_subaccount.mt940' }

            it 'fails with an error' do
              expect { import }.to raise_error(ImportBankStatement::InvalidInput)
            end
          end
        end

        describe 'database record creation' do
          describe 'bank statement already exists' do
            let!(:bank_statement) { BankStatement.create(account_id: account.id, sequence: '5/1') }

            it 'does not create a new bank statement' do
              expect { import }.to_not change { BankStatement.count }
            end

            it 'returns the existing bank statement' do
              expect(import).to eq(bank_statement)
            end
          end

          describe 'bank statement does not yet exist' do
            it 'creates a new bank statement' do
              expect { import }.to change { BankStatement.count }.by(1)
            end

            it 'returns a bank statement record' do
              expect(import).to be_an_instance_of(BankStatement)
            end
          end
        end

        describe 'account balance updates' do
          context 'no old balance is set' do
            before { account.set_balance(nil, nil) }

            it 'stores new closing balance date' do
              expect { import }.to change { account.reload.balance_date }
            end

            it 'stores new closing balance' do
              expect { import }.to change { account.reload.balance_in_cents }
            end
          end

          context 'an old statement is added' do
            let(:mt940_fixture) { 'single_valid_2016-03-15.mt940' }

            before { account.set_balance(Date.new(2016, 03, 20), 1_000_00) }

            it 'does not change closing balance date' do
              expect { import }.to_not change { account.reload.balance_date }
            end

            it 'does not change closing balance date' do
              expect { import }.to_not change { account.reload.balance_in_cents }
            end
          end

          context 'a new bank statement is imported' do
            let(:mt940_fixture) { 'single_valid_2016-03-15.mt940' }

            before { account.set_balance(Date.new(2016, 03, 10), 1_000_00) }

            it 'stores new closing balance date' do
              expect { import }.to change { account.reload.balance_date }
            end

            it 'stores new closing balance' do
              expect { import }.to change { account.reload.balance_in_cents }
            end
          end
        end
      end
    end
  end
end
