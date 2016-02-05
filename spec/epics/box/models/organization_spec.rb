require 'active_support/all'

module Epics
  module Box
    RSpec.describe Organization do

      describe 'callbacks' do
        subject(:organization) { described_class.create(name: "Mega Corps") }

        it 'has a random webhook token' do
          expect(organization.webhook_token).to be_present
        end
      end
    end
  end
end
