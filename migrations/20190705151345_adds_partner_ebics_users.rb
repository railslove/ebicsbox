Sequel.migration do
  up do
    add_column :ebics_users, :partner, String
  end

  down do
    drop_column :ebics_users, :partner
  end
end
