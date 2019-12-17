# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table :statements do
      drop_index :sha

      rename_column :sha, :sha2
      add_index :sha2, unique: true

      add_column :sha, :text
      add_index :sha, unique: true
    end

    require 'rake'
    load 'Rakefile'

    Rake::Task['migration_tasks:calculate_new_sha'].invoke
  end

  down do
    alter_table :statements do
      drop_column :sha
      drop_index :sha
      drop_index :sha2

      rename_column :sha2, :sha
      add_index :sha, unique: true
    end
  end
end
