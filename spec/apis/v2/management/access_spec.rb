# frozen_string_literal: true

require 'spec_helper'

module Box
  RSpec.describe Apis::V2::Management do
    include_context 'admin user'

    let(:other_organization) { Fabricate(:organization) }

    describe 'Access' do
      context 'Unauthorized user' do
        it 'returns a 401 unauthorized code' do
          get 'management/'
          expect_status 401
        end

        it 'includes an error message' do
          get 'management/'
          expect_json 'message', 'Unauthorized access. Please provide a valid organization management token!'
        end
      end

      context 'non-admin user' do
        before { user.update(admin: false) }

        it 'denies access to the app' do
          get 'management/', TestHelpers::VALID_HEADERS
          expect_status 401
        end
      end

      context 'admin user' do
        it 'grants access to the app' do
          get 'management/', TestHelpers::VALID_HEADERS
          expect_status 200
        end
      end
    end
  end
end
