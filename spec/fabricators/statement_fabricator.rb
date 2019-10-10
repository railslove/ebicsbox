# frozen_string_literal: true

require 'faker'
require 'securerandom'

require_relative '../../box/models/statement'

I18n.reload!

FAKE_STATEMENT_IBANS = %w[
  DE94687694226632298921
  DE21839160062359143795
  DE35933204478877197156
  DE93915893024678522199
  DE60196037174247714871
  DE31911981696357363391
  DE65879081069190668331
  DE03913893489031517226
  DE32762535285791734619
  DE02031809781781083301
].freeze

STATEMENT_BICS = %w[
  GENODEF1NDH
  DEUTDEDB267
  DEUTDEDB926
  DEUTDEDB927
  DEUTDEDB928
  DEUTDE3B267
  DEUTDE3B274
  DEUTDE3B273
  DEUTDE3B275
  COBADEFFXXX
].freeze

Fabricator(:statement, from: 'Box::Statement') do
  public_id { SecureRandom.uuid }
  date { Date.today }
  amount { rand(0..100_000) }
  sign { [-1, 1].sample }
  debit { [true, false].sample }
  name { Faker::Name.name }
  iban { FAKE_STATEMENT_IBANS.sample }
  bic { STATEMENT_BICS.sample }
  eref { "eref-#{Fabricate.sequence(:eref)}" }
  svwz { Faker::Lorem.sentence }
end
