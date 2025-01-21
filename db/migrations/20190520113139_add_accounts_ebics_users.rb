# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:accounts_ebics_users) do
      Integer :account_id
      Integer :ebics_user_id
      DateTime :created_at, default: Sequel.function(:now)
    end

    self[:ebics_users].each do |ebics_user|
      self[:accounts_ebics_users].insert(account_id: ebics_user[:account_id], ebics_user_id: ebics_user[:id])
    end
  end

  down do
    drop_table :accounts_ebics_users
  end
end
