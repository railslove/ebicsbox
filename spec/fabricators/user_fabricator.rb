# frozen_string_literal: true

require_relative "../../box/models/ebics_user"

Fabricator(:user, from: "Box::User") do
  organization { Fabricate(:organization) }
  name { Faker::Name.name }
  email { Faker::Internet.email }
  admin false
end

Fabricator(:admin, from: :user) do
  admin true
end
