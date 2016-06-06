RSpec.configure do |config|
  config.around(:each, verify_stubs: false) do |ex|
    config.mock_with :rspec do |mocks|
      mocks.verify_partial_doubles = false
      begin
        ex.run
      ensure
        mocks.verify_partial_doubles = true
      end
    end
  end
end
