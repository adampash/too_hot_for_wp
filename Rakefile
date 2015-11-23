require_relative './app'
require 'standalone_migrations'
StandaloneMigrations::Tasks.load_tasks

task :default => :migrate

desc "Run migrations"
task :migrate do
  ActiveRecord::Migrator.migrate('db/migrate', ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
end

desc "Scrape articles for deletion"
task :scrape do
  require_relative './wiki_scrape'
  ts = WikiScrape.new
  ts.fetch_and_save_all_articles
  Article.check_all_for_deletions
end
