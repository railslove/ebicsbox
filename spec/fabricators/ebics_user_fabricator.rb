require_relative '../../box/models/ebics_user'

Fabricator(:ebics_user, from: 'Box::EbicsUser') do
  remote_user_id { Faker::Internet.user_name.upcase }
  signature_class "T"
end

Fabricator(:activated_ebics_user, from: :ebics_user) do
  activated_at { Date.today }
end
