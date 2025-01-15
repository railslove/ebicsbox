# frozen_string_literal: true

Sequel.migration do
  up do
    drop_column :ebics_users, :account_id
  end

  down do
    add_column :ebics_users, :account_id, Integer
  end
end
