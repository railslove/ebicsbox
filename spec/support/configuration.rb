
RSpec.configure do |config|
  config.before do
    allow_any_instance_of(Ebics::Box::Configuration).to receive(:db_passphrase).and_return('secret')
  end
end
