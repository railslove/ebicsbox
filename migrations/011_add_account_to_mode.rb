Sequel.migration do
  change do
    add_column :accounts, :mode, String
  end
end
