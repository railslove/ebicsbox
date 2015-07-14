Sequel.migration do
  up do
    add_column :accounts, :submitted_at, DateTime
  end

  down do
    drop_column :accounts, :submitted_at
  end
end
