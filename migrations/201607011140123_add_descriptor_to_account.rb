Sequel.migration do
  up do
    add_column :accounts, :descriptor, String
  end

  down do
    drop_column :accounts, :descriptor
  end
end
