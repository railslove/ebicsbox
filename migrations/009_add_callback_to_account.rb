Sequel.migration do
  change do
    add_column :accounts, :callback_url, String
  end
end
