Sequel.migration do
  up do
    unless DB[:organizations].columns.include?(:webhook_token)
      add_column :organizations, :webhook_token, String
    end
  end

  down do
    # ignore
  end
end
