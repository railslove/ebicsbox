Sequel.migration do
  up do
    add_column :organizations, :webhook_token, String
  end

  down do
    drop_column :organizations, :webhook_token
  end
end
