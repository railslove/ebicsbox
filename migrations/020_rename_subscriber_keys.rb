Sequel.migration do
  up do
    rename_column :subscribers, :keys, :encryption_keys
  end

  down do
    rename_column :subscribers, :encryption_keys, :keys
  end
end
