Sequel.migration do
  up do
    drop_column :accounts, :passphrase
  end

  down do
    add_column :accounts, :passphrase, String
  end
end
