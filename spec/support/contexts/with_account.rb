RSpec.shared_context "with account" do
  let!(:account) { organization.add_account(name: 'My test account', iban: 'MYTESTIBAN', bic: 'MYTESTBIC') }
end
