Sequel.migration do
  up do
    create_table :accounts do
      primary_key :id
      String :iban
      String :bic
      String :creditor_identifier
      String :name
      String :url
      String :host
      String :partner
      String :user
      String :passphrase
      Text   :keys
    end
  end

  down do
    drop_table(:accounts)
  end
end
