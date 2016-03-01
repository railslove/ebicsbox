Sequel.migration do
  up do
    drop_column :organizations, :management_token
    add_column :users, :admin, :boolean, default: false
    run "UPDATE users SET admin = 't'"
  end

  down do
    drop_column :users, :admin
    add_column :organizations, :management_token, String
  end
end
