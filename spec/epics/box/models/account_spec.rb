module Epics
  module Box
    RSpec.describe Account do
      describe 'acticated?' do
        specify do
          expect(Account.new(activated_at: Time.now)).to be_active
        end
      end

      describe '.all_ids' do
        it 'returns an empty array if no accounts are created yet' do
          expect(Account.all_ids).to eq([])
        end

        it 'returns all account ids' do
          accounts = Array.new(2).map { Account.create }
          expect(Account.all_ids).to eq(accounts.map(&:id))
        end
      end

      describe '#imported_at!' do
        let(:account) { Account.create }

        it 'adds a new import for the account and the given day' do
          expect{ account.imported_at!(Date.today) }.to change { DB[:imports].where(account_id: account.id).count }.by(1)
        end
      end

      describe '#setup!' do
        let(:account) { Account.create(mode: 'File', user: 'user', host: 'host', url: 'url', partner: 'partner') }

        context 'incomplete ebics data' do
          before { account.update(user: nil) }

          it 'fails to submit' do
            expect { account.setup! }.to raise_error(Account::IncompleteEbicsData)
          end
        end

        context 'ini already sent' do
          before { account.update(ini_letter: 'some data') }

          it 'fails if reset flag is not set' do
            expect { account.setup! }.to raise_error(Account::AlreadyActivated)
          end
        end

        it 'saves the keys' do
          account.update(key: nil)
          account.setup!
          expect(account.reload.key).to eql(Epics::Box::Account::File.new.dump_keys)
        end

        it 'saves the ini letter' do
          account.update(ini_letter: nil)
          account.setup!
          expect(account.reload.ini_letter).to eql(Epics::Box::Account::File.new.ini_letter(account.bankname))
        end

        it 'calls INI and HIA' do
          expect_any_instance_of(Epics::Box::Account::File).to receive(:INI)
          expect_any_instance_of(Epics::Box::Account::File).to receive(:HIA)
          account.setup!
        end
      end

      describe '#activate' do
        let(:account) { Account.create(mode: 'File') }

        it 'saves activation date' do
          account.update(activated_at: nil)
          account.activate!
          expect(account.reload.activated_at).to be_instance_of(Time)
        end

        it 'exchanges the keys' do
          expect(account.client).to receive(:HPB)
          account.update(key: nil)
          account.activate!
          expect(account.reload.key).to eql(Epics::Box::Account::File.new.dump_keys)
        end

        context 'error case' do
          let(:account) { Account.create(mode: 'File') }
          it 'catches the epics error and returns false' do
            expect(account.client).to receive(:HPB).and_raise(Epics::Error::BusinessError.new('nope'))
            expect(account.activate!).to eql(false)
          end
        end
      end

      describe '#last_imported_at' do
        let(:account) { Account.create }

        context 'account has just been created' do
          it 'returns nil' do
            expect(account.last_imported_at).to be_nil
          end
        end

        context 'account has already some imports' do
          before do
            account.imported_at!(2.days.ago)
            account.imported_at!(3.days.ago)
          end

          it 'returns date of last import' do
            expect(account.last_imported_at).to eq(2.days.ago.to_date)
          end
        end
      end
    end
  end
end
