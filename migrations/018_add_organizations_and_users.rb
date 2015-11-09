Sequel.migration do
  up do
    create_table :organizations do
      primary_key :id
      String :name
      DateTime :created_at, default: 'NOW()'
    end

    create_table :users do
      primary_key :id
      Integer :organization_id
      String :name
      String :access_token
      DateTime :created_at, default: 'NOW()'
    end

    create_table :subscribers do
      primary_key :id
      Integer :account_id
      Integer :user_id
      String   :remote_user_id
      Text   :keys
      String :signature_class, size: 1
      DateTime :created_at, default: 'NOW()'
      DateTime :activated_at
    end

    add_column :accounts, :organization_id, Integer

    # Create an organization and user to access all data
    orga_id = self[:organizations].insert(name: 'Primary Organization')
    user_id = self[:users].insert(organization_id: orga_id, name: 'Primary user', access_token: SecureRandom.hex(24))

    # Transform account data model to use new subscribers
    self[:accounts].update(organization_id: orga_id)
    self[:accounts].all do |account|
      self[:subscribers].insert(
        account_id: account[:id],
        user_id: user_id,
        remote_user_id: account[:user],
        keys: account[:key],
        activated_at: account[:activated_at],
        signature_class: 'E'
      )
    end
  end

  down do
    drop_column :accounts, :organization_id
    drop_table(:subscribers)
    drop_table(:users)
    drop_table(:organizations)
  end
end
