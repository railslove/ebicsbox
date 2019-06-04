RSpec.shared_context "with other account" do
  let!(:other_account) do
    organization.add_account(name: 'Other test account', iban: 'OTHERTESTIBAN', bic: 'OTHERTESTBIC')
  end
end
