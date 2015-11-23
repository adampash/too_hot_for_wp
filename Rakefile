require './article'

require 'standalone_migrations'
StandaloneMigrations::Tasks.load_tasks

task :default => :migrate

desc "Run migrations"
task :migrate do
  ActiveRecord::Migrator.migrate('db/migrate', ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
end
