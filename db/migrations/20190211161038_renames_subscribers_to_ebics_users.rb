# frozen_string_literal: true

Sequel.migration do
  up do
    rename_table :subscribers, :ebics_users
  end

  down do
    rename_table :ebics_users, :subscribers
  end
end
