require 'active_support/all'

module Box
  RSpec.describe Organization do

    describe 'register' do
      subject(:organization) { described_class.register(name: "Mega Corps") }

      it 'has a random webhook token' do
        expect(organization.webhook_token).to be_present
      end
    end
  end
end
