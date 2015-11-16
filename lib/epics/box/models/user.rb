class Epics::Box::User < Sequel::Model
  self.raise_on_save_failure = true

  many_to_one :organization
  one_to_many :subscribers

  def self.find_by_access_token(access_token)
    first(access_token: access_token)
  end
end
