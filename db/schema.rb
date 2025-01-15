Sequel.migration do
  change do
    create_table(:accounts) do
      primary_key :id
      column :iban, "text"
      column :bic, "text"
      column :creditor_identifier, "text"
      column :name, "text"
      column :url, "text"
      column :host, "text"
      column :partner, "text"
      column :callback_url, "text"
      column :mode, "text"
      column :bankname, "text"
      column :organization_id, "integer"
      column :balance_in_cents, "integer"
      column :balance_date, "date"
      column :statements_format, "text", :default=>"mt940"
      column :config, "json", :default=>Sequel::LiteralString.new("'{}'::json")
      column :descriptor, "text"
    end
    
    create_table(:accounts_ebics_users) do
      column :account_id, "integer"
      column :ebics_user_id, "integer"
      column :created_at, "timestamp without time zone", :default=>Sequel::CURRENT_TIMESTAMP
    end
    
    create_table(:bank_statements) do
      primary_key :id
      column :account_id, "integer"
      column :remote_account, "text"
      column :sequence, "text"
      column :opening_balance, "numeric(15,2)"
      column :closing_balance, "numeric(15,2)"
      column :transaction_count, "integer"
      column :fetched_on, "date"
      column :content, "text"
      column :year, "integer"
      column :sha, "text"
      
      index [:sha]
    end
    
    create_table(:ebics_users) do
      primary_key :id
      column :user_id, "integer"
      column :remote_user_id, "text"
      column :encryption_keys, "text"
      column :signature_class, "character varying(1)"
      column :created_at, "timestamp without time zone", :default=>Sequel::CURRENT_TIMESTAMP
      column :activated_at, "timestamp without time zone"
      column :ini_letter, "text"
      column :submitted_at, "timestamp without time zone"
      column :partner, "text"
    end
    
    create_table(:events) do
      primary_key :id
      column :account_id, "integer"
      column :type, "text"
      column :public_id, "uuid", :default=>Sequel::LiteralString.new("uuid_generate_v4()")
      column :payload, "json", :default=>Sequel::LiteralString.new("'{}'::json")
      column :triggered_at, "timestamp without time zone", :default=>Sequel::CURRENT_TIMESTAMP
      column :signature, "text"
      column :webhook_status, "text", :default=>"pending"
      column :webhook_retries, "integer", :default=>0
    end
    
    create_table(:imports) do
      primary_key :id
      column :date, "date"
      column :duration, "integer"
      column :transactions_count, "integer"
      column :account_id, "integer"
    end
    
    create_table(:organizations) do
      primary_key :id
      column :name, "text"
      column :created_at, "timestamp without time zone", :default=>Sequel::CURRENT_TIMESTAMP
      column :webhook_token, "text", :null=>false
    end
    
    create_table(:schema_migrations) do
      column :filename, "text", :null=>false
      
      primary_key [:filename]
    end
    
    create_table(:statements) do
      primary_key :id
      column :sha_bak, "text"
      column :date, "date"
      column :entry_date, "date"
      column :amount, "integer"
      column :sign, "integer"
      column :debit, "boolean"
      column :swift_code, "text"
      column :reference, "text"
      column :bank_reference, "text"
      column :bic, "text"
      column :iban, "text"
      column :name, "text"
      column :eref, "text"
      column :mref, "text"
      column :svwz, "text"
      column :creditor_identifier, "text"
      column :information, "text"
      column :description, "text"
      column :transaction_code, "text"
      column :details, "text"
      column :account_id, "integer"
      column :transaction_id, "integer"
      column :bank_statement_id, "integer"
      column :public_id, "uuid", :default=>Sequel::LiteralString.new("uuid_generate_v4()")
      column :settled, "boolean", :default=>true
      column :sha, "text"
      column :tx_id, "text"
      
      index [:sha], :name=>:statements_sha2_index, :unique=>true
      index [:sha_bak], :name=>:statements_sha_key, :unique=>true
    end
    
    create_table(:transactions) do
      primary_key :id
      column :eref, "text"
      column :type, "text"
      column :payload, "text"
      column :ebics_order_id, "text"
      column :ebics_transaction_id, "text"
      column :status, "text"
      column :account_id, "integer"
      column :order_type, "text"
      column :amount, "integer"
      column :user_id, "integer"
      column :created_at, "timestamp without time zone"
      column :public_id, "uuid", :default=>Sequel::LiteralString.new("uuid_generate_v4()"), :null=>false
      column :history, "json", :default=>Sequel::LiteralString.new("'[]'::json")
      column :currency, "text", :default=>"EUR"
      column :metadata, "json", :default=>Sequel::LiteralString.new("'{}'::json")
      
      index [:eref], :name=>:transactions_eref_key, :unique=>true
    end
    
    create_table(:users) do
      primary_key :id
      column :organization_id, "integer"
      column :name, "text"
      column :access_token, "text"
      column :created_at, "timestamp without time zone", :default=>Sequel::CURRENT_TIMESTAMP
      column :admin, "boolean", :default=>false
      column :email, "text"
    end
    
    create_table(:webhook_deliveries) do
      primary_key :id
      column :event_id, "integer"
      column :delivered_at, "timestamp without time zone"
      column :response_body, "text"
      column :reponse_headers, "json", :default=>Sequel::LiteralString.new("'{}'::json")
      column :response_status, "integer"
      column :response_time, "integer"
    end
  end
end
