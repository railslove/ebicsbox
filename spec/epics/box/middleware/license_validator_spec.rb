require 'epics/box/middleware/license_validator'

module Epics
  module Box
    module Middleware
      RSpec.describe LicenseValidator do

        around do |example|
          ENV['REPLICATED_INTEGRATIONAPI']="http://license.in"
          example.run
          ENV['REPLICATED_INTEGRATIONAPI']=nil
        end

        let(:app) { double(call: true) }
        let(:env) { {} }

        subject { described_class.new(app) }

        describe 'when license is expired' do
          it 'shall not pass!' do
            stub_request(:get, "http://license.in/license/v1/license").
             to_return(:status => 200, :body => '{"fields":[{"field":"max_hosts","value":1},{"field":"min_hosts","value":1}],"expiration_time":"2012-06-30T00:00:00Z"}')

            expect(subject.call(env)).to eq [431, {'Content-Type' => env["Content-Type"], "Content-Length" => "0", "X-Ebics-Box-License-Valid" => "false"}, []]
          end
        end

        describe 'when license is not expired' do
          it 'will let you through' do
            stub_request(:get, "http://license.in/license/v1/license").
             to_return(:status => 200, :body => %Q{{"fields":[{"field":"max_hosts","value":1},{"field":"min_hosts","value":1}],"expiration_time":"#{DateTime.now + 10}"}})

            expect(subject.call(env)).to be(true)
          end
        end

        describe 'when license never expires' do
          it 'will let you through' do
            stub_request(:get, "http://license.in/license/v1/license").
             to_return(:status => 200, :body => '{"fields":[{"field":"max_hosts","value":1},{"field":"min_hosts","value":1}]}')

            expect(subject.call(env)).to be(true)
          end
        end

      end
    end
  end
end
