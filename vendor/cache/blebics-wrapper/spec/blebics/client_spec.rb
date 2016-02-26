require 'spec_helper'
Debugger.start
RSpec.describe Blebics::Client do

  subject { described_class.new( File.read(File.join( File.dirname(__FILE__), '..', 'fixtures', 'SIZBN001.key')), 'secret' , 'https://194.180.18.30/ebicsweb/ebicsweb', 'SIZBN001', 'EBIX', 'EBICS') }

  describe 'attributes' do
    it { expect(subject.host_id).to eq('SIZBN001') }
    it { expect(subject.keys_content).to match(/SIZBN001.E002/) }
    it { expect(subject.passphrase).to eq('secret') }
    it { expect(subject.partner_id).to eq('EBICS') }
    it { expect(subject.url).to eq('https://194.180.18.30/ebicsweb/ebicsweb') }
    it { expect(subject.user_id).to eq('EBIX') }
  end

  describe 'bank' do
    it { expect(subject.bank).to be_kind_of(EbicsBankImpl) }
  end

  describe 'partner' do
    it { expect(subject.partner).to be_kind_of(EbicsPartnerImpl) }
  end

  describe 'user' do
    it { expect(subject.user).to be_kind_of(Blebics::User) }
  end

  describe 'session' do
    it { expect(subject.session).to be_kind_of(EbicsSession) }
  end

  describe 'key_management' do
    it { expect(subject.key_management).to be_kind_of(KeyManagement) }
  end

  describe 'distributed_signature' do
    it { expect(subject.send(:distributed_signature)).to be_kind_of(Blebics::DistributedElectronicSignature) }
  end

  describe '#dump_keys' do
    it 'should dump correctly' do
      result = JSON.load(subject.send(:dump_keys))
      private_key = result["SIZBN001.E002"]
      private_key = subject.send(:decrypt, private_key)
      expect(subject.keys["SIZBN001.E002"]).to eq private_key
    end
  end

  describe '#HTD' do
    before do
      allow(subject).to receive(:download).and_return( File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'xml', 'htd_order_data.xml')))
    end

    it 'sets @iban' do
      expect { subject.HTD }.to change { subject.instance_variable_get("@iban") }
    end

    it 'sets @bic' do
      expect { subject.HTD }.to change { subject.instance_variable_get("@bic") }
    end

    it 'sets @name' do
      expect { subject.HTD }.to change { subject.instance_variable_get("@name") }
    end
  end

  describe '#e' do
    it { expect(subject.e).to be_kind_of(E002PrivateKey) }
  end

  describe '#x' do
    it { expect(subject.x).to be_kind_of(X002PrivateKey) }
  end

  describe '#a' do
    it { expect(subject.a).to be_kind_of(A006PrivateKey) }
  end

  describe '#bank_e' do
    it { expect(subject.bank_e).to be_kind_of(E002PublicKey) }
  end

  describe '#bank_x' do
    it { expect(subject.bank_x).to be_kind_of(X002PublicKey) }
  end
end
