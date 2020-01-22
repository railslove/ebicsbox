# frozen_string_literal: true

Sequel.migration do
  up do
    drop_column :statements, :sha
    add_column :statements, :sha, :text
    add_index :statements, :sha, unique: true
  end

  down do
    # noop
  end
end
