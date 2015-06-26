Sequel.migration do
  change do
    add_column :accounts, :bankname, String
    add_column :accounts, :ini_letter, String
    add_column :accounts, :activated_at, DateTime
  end
end
