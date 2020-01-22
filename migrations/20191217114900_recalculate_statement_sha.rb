# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table :statements do
      add_column :sha2, :text
      add_index :sha2, unique: true
    end

    require 'rake'
    load 'Rakefile'

    Rake::Task['migration_tasks:calculate_new_sha'].invoke

    alter_table :statements do
      rename_column :sha, :sha_bak
      rename_column :sha2, :sha
    end
  end

  down do
    alter_table :statements do
      drop_column :sha
      rename_column :sha_bak, :sha
    end
  end
end
