Sequel.migration do
  up do
    drop_column :accounts, :user
    drop_column :accounts, :key
    drop_column :accounts, :ini_letter
    drop_column :accounts, :activated_at
    drop_column :accounts, :submitted_at
  end

  down do
    add_column :accounts, :submitted_at, DateTime
    add_column :accounts, :activated_at, DateTime
    add_column :accounts, :ini_letter, String
    add_column :accounts, :key, String
    add_column :accounts, :user, String
  end
end
