Sequel.migration do
  up do
    create_table :transactions do
      primary_key :id
      String :eref, unique: true
      String :type
      String :payload
      String :ebics_order_id
      String :ebics_transaction_id
      String :status
    end
  end

  down do
    drop_table(:transactions)
  end
end
