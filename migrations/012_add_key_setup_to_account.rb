Sequel.migration do
  change do
    add_column :accounts, :bankname, String
    add_column :accounts, :ini_letter, String
  end
end
