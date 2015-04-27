Sequel.migration do
  change do
    rename_column :accounts, :keys, :key
  end
end
