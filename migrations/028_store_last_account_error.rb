Sequel.migration do
  up do
    add_column :accounts, :last_error, String
    add_column :accounts, :last_error_at, DateTime
  end

  down do
    drop_column :accounts, :last_error_at
    drop_column :accounts, :last_error
  end
end
