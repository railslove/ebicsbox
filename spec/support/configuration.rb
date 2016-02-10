
RSpec.configure do |config|
  config.before do
    allow_any_instance_of(Box::Configuration).to receive(:secret_token).and_return('0051d88d2c5fac5b6efda65e17d5290ddb946624')
    allow_any_instance_of(Box::Configuration).to receive(:db_passphrase).and_return('secret')
  end
end
