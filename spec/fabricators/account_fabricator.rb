require 'faker'

require_relative '../../box/models/account'

I18n.reload!

FAKE_IBANS = [
  "DE75374497411708271691",
  "DE75118811396141990072",
  "DE87074878374415317289",
  "DE58942172612089832159",
  "DE31316996782341355884",
  "DE16059459097017372675",
  "DE83858599941090758112",
  "DE26293947990833146558",
  "DE18054112104998089173",
  "DE89768362554826541083",
]

BICS = [
  "GENODEF1NDH",
  "DEUTDEDB267",
  "DEUTDEDB926",
  "DEUTDEDB927",
  "DEUTDEDB928",
  "DEUTDE3B267",
  "DEUTDE3B274",
  "DEUTDE3B273",
  "DEUTDE3B275",
  "COBADEFFXXX",
]

Fabricator(:account, from: 'Box::Account') do
  name { Faker::Company.name }
  descriptor { Faker::Company.name }
  iban { FAKE_IBANS.sample }
  bic { BICS.sample }

  # Fake a balance
  balance_date { Date.today }
  balance_in_cents { Random.rand(1_000_00) }

  # EBICS Configuration
  url "http://my-ebics-server.url/ebicshost"
  partner "PARTNER_ID"
  host "HOST_ID"

  # Account configuration
  creditor_identifier 'DE98ZZZ09999999999'
  callback_url "https://myapp.url/webhooks"
end

Fabricator(:activated_account, from: :account) do
  after_create do |account|
    Fabricate(:activated_subscriber, account_id: account.id)
  end
end
