# frozen_string_literal: true

require 'spec_helper'

module Box
  module Apis
    module V1
      RSpec.describe Service do
        include_context 'valid user'

        context 'requiring version 1 explicitly' do
          it 'returns currently used version' do
            get '/', 'Accept' => 'application/vnd.ebicsbox-v1+json', 'Authorization' => 'Bearer test-token'
            expect_json 'version', 'v1'
          end
        end

        context 'default version' do
          it 'returns currently used version' do
            get '/', 'Authorization' => 'Bearer test-token'
            expect_json 'version', 'v1'
          end
        end
      end
    end
  end
end
