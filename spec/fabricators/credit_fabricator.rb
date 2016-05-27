require_relative '../../box/models/transaction'

Fabricator(:credit, from: 'Box::Transaction') do
  eref { Fabricate.sequence(:credit) { |i| "credit-#{i}" } }
  type 'credit'
  # payload
  ebics_transaction_id 'B00U'
  status { %w[created file_upload funds_debited].sample }
  account_id 1
  order_type 'CCT'
  amount 123_45
  user_id 1
end
