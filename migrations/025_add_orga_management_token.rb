Sequel.migration do
  up do
    add_column :organizations, :management_token, String
  end

  down do
    drop_column :organizations, :management_token
  end
end
