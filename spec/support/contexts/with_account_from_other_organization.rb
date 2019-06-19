RSpec.shared_context "with account from other organization" do
  let!(:other_organization) { Fabricate(:organization) }
  let!(:other_account) do
    other_organization.add_account(name: 'Other test account', iban: 'OTHERTESTIBAN', bic: 'OTHERTESTBIC')
  end
end
