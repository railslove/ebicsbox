module Box
  RSpec.describe EbicsUser do
    describe 'acticated?' do
      specify do
        expect(described_class.new(activated_at: Time.now)).to be_active
      end
    end

    describe '#setup!' do
      let(:account) { Account.create(mode: 'File', url: 'url', host: 'host', partner: 'partner') }
      let(:user) { User.create(name: 'John Doe') }
      subject do
        described_class.create(user: user, remote_user_id: 'user').tap do |ebics_user|
          ebics_user.add_account(account)
        end
      end

      context 'incomplete ebics data' do
        before { subject.update(remote_user_id: nil) }

        it 'fails to submit' do
          expect { subject.setup!(account) }.to raise_error(EbicsUser::IncompleteEbicsData)
        end
      end

      context 'ini already sent' do
        before do
          subject.update(ini_letter: 'some data')
          allow(account).to receive(:client_adapter)
        end

        it 'does not send them again if reset-flag not set' do
          subject.setup!(account)
          expect(account).not_to have_received(:client_adapter)
        end
      end

      it 'saves the keys' do
        subject.update(encryption_keys: nil)
        subject.setup!(account)
        expect(subject.reload.encryption_keys).to eql(Adapters::File.new.dump_keys)
      end

      it 'saves the ini letter' do
        subject.update(ini_letter: nil)
        subject.setup!(account)
        expect(subject.reload.ini_letter).to eql(Adapters::File.new.ini_letter(account.bankname))
      end

      it 'calls INI and HIA' do
        expect_any_instance_of(Adapters::File).to receive(:INI)
        expect_any_instance_of(Adapters::File).to receive(:HIA)
        subject.setup!(account)
      end
    end

    describe '#activate!' do
      let(:account) { Account.create(mode: 'File', url: 'url', host: 'host', partner: 'partner') }
      let(:user) { User.create(name: 'John Doe') }
      subject do
        described_class.create(user: user).tap do |ebics_user|
          ebics_user.add_account(account)
        end
      end

      before do
        allow(Account).to receive(:[]).and_return(double('account', organization: double('orga', webhook_token: 'token')))
      end

      it 'is truthy on success' do
        expect(subject.activate!).to be(true)
      end

      it 'saves activation date' do
        subject.update(activated_at: nil)
        subject.activate!
        expect(subject.reload.activated_at).to be_instance_of(Time)
      end

      it 'exchanges the keys' do
        expect(subject.client).to receive(:HPB)
        subject.update(encryption_keys: nil)
        subject.activate!
        expect(subject.reload.encryption_keys).to eql(Adapters::File.new.dump_keys)
      end

      context 'error case' do
        before do
          expect(subject.client).to receive(:HPB).and_raise(Epics::Error::BusinessError.new('nope'))
        end

        it 'catches the epics error and returns false' do
          expect(subject.activate!).to eql(false)
        end
      end
    end
  end
end
