# frozen_string_literal: true

Sequel.migration do
  change do
    run 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'
    DB.extension :pg_json

    unless tables.include?(:accounts)
      create_table(:accounts) do
        primary_key :id
        String :iban, text: true
        String :bic, text: true
        String :creditor_identifier, text: true
        String :name, text: true
        String :url, text: true
        String :host, text: true
        String :partner, text: true
        String :callback_url, text: true
        String :mode, text: true
        String :bankname, text: true
        Integer :organization_id
        Integer :balance_in_cents
        Date :balance_date
        String :statements_format, default: 'mt940', text: true
        String :config, type: :json, default: Sequel.pg_json({})
        String :descriptor, text: true
      end
    end

    unless tables.include?(:bank_statements)
      create_table(:bank_statements) do
        primary_key :id
        Integer :account_id
        String :remote_account, text: true
        String :sequence, text: true
        BigDecimal :opening_balance, size: [15, 2]
        BigDecimal :closing_balance, size: [15, 2]
        Integer :transaction_count
        Date :fetched_on
        String :content, text: true
        Integer :year
      end
    end

    unless tables.include?(:events)
      create_table(:events) do
        primary_key :id
        Integer :account_id
        String :type, text: true
        String :public_id, type: :uuid, default: Sequel.function(:uuid_generate_v4)
        String :payload, type: :json, default: Sequel.pg_json({})
        DateTime :triggered_at, default: Sequel.function(:now)
        String :signature, text: true
        String :webhook_status, default: 'pending', text: true
        Integer :webhook_retries, default: 0
      end
    end

    unless tables.include?(:imports)
      create_table(:imports) do
        primary_key :id
        Date :date
        Integer :duration
        Integer :transactions_count
        Integer :account_id
      end
    end

    unless tables.include?(:organizations)
      create_table(:organizations) do
        primary_key :id
        String :name, text: true
        DateTime :created_at, default: Sequel.function(:now)
        String :webhook_token, text: true, null: false
      end
    end

    unless tables.include?(:statements)
      create_table(:statements, ignore_index_errors: true) do
        primary_key :id
        String :sha, text: true
        Date :date
        Date :entry_date
        Integer :amount
        Integer :sign
        TrueClass :debit
        String :swift_code, text: true
        String :reference, text: true
        String :bank_reference, text: true
        String :bic, text: true
        String :iban, text: true
        String :name, text: true
        String :eref, text: true
        String :mref, text: true
        String :svwz, text: true
        String :creditor_identifier, text: true
        String :information, text: true
        String :description, text: true
        String :transaction_code, text: true
        String :details, text: true
        Integer :account_id
        Integer :transaction_id
        Integer :bank_statement_id
        String :public_id, type: :uuid, null: false, default: Sequel.function(:uuid_generate_v4)

        index [:sha], name: :statements_sha_key, unique: true
      end
    end

    unless tables.include?(:subscribers)
      create_table(:subscribers) do
        primary_key :id
        Integer :account_id
        Integer :user_id
        String :remote_user_id, text: true
        String :encryption_keys, text: true
        String :signature_class, size: 1
        DateTime :created_at, default: Sequel.function(:now)
        DateTime :activated_at
        String :ini_letter, text: true
        DateTime :submitted_at
      end
    end

    unless tables.include?(:transactions)
      create_table(:transactions, ignore_index_errors: true) do
        primary_key :id
        String :eref, text: true
        String :type, text: true
        String :payload, text: true
        String :ebics_order_id, text: true
        String :ebics_transaction_id, text: true
        String :status, text: true
        Integer :account_id
        String :order_type, text: true
        Integer :amount
        Integer :user_id
        DateTime :created_at
        String :public_id, type: :uuid, null: false, default: Sequel.function(:uuid_generate_v4)
        String :history, type: :json, default: Sequel.pg_json([])

        index [:eref], name: :transactions_eref_key, unique: true
      end
    end

    unless tables.include?(:users)
      create_table(:users) do
        primary_key :id
        Integer :organization_id
        String :name, text: true
        String :access_token, text: true
        DateTime :created_at, default: Sequel.function(:now)
        TrueClass :admin, default: false
        String :email, text: true
      end
    end

    unless tables.include?(:webhook_deliveries)
      create_table(:webhook_deliveries) do
        primary_key :id
        Integer :event_id
        DateTime :delivered_at
        String :response_body, text: true
        String :reponse_headers, type: :json, default: Sequel.pg_json({})
        Integer :response_status
        Integer :response_time
      end
    end
  end
end
