require_relative '../../box/models/subscriber'

Fabricator(:subscriber, from: 'Box::Subscriber') do
  remote_user_id { Faker::Internet.user_name.upcase }
  signature_class "T"
end

Fabricator(:activated_subscriber, from: :subscriber) do
  activated_at { Date.today }
end
