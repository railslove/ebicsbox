# frozen_string_literal: true

Sequel.migration do
  up do
    add_column :ebics_users, :partner, String

    require "rake"
    load "Rakefile"
    Rake::Task["migration_tasks:copy_partners"].invoke
  end

  down do
    drop_column :ebics_users, :partner
  end
end
