class Epics::Box::Organization < Sequel::Model
  self.raise_on_save_failure = true

  one_to_many :accounts
  one_to_many :users
end
