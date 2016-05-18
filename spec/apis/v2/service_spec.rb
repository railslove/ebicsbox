require 'spec_helper'

module Box
  module Apis
    module V2
      RSpec.describe Service do
        include_context 'valid user'

        it 'returns currently used version' do
          get '/', { 'Accept' => 'application/vnd.ebicsbox-v2+json', 'Authorization' => 'Bearer test-token' }
          expect_json 'version', 'v2'
        end
      end
    end
  end
end
