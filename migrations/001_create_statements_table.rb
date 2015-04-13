Sequel.migration do
  up do
    create_table :statements do
      primary_key :id
      String :sha, unique: true
      Date :date
      Date :entry_date
      Integer :amount_cents
      Integer :sign
      TrueClass :debit
      String  :swift_code
      String  :reference
      String  :bank_reference
      String  :bic
      String  :iban
      String  :name
      String  :eref
      String  :mref
      String  :svwz
      String  :creditor_identifier
      String  :information
      String  :description
      String  :transaction_code
      String  :details
    end
  end

  down do
    drop_table(:statements)
  end
end
