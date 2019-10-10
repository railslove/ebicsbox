# frozen_string_literal: true

require 'securerandom'
require 'sequel'

module Box
  class BankStatement < Sequel::Model
    self.raise_on_save_failure = true

    many_to_one :account
    one_to_many :statements
  end
end
