def database_configuration
  path = './config/database.yml'
  yaml = Pathname.new(path) if path

  config = if yaml && yaml.exist?
             require "yaml"
             require "erb"
             YAML.load(ERB.new(yaml.read).result) || {}
           elsif ENV['DATABASE_URL']
             # Value from ENV['DATABASE_URL'] is set to default database connection
             # by Active Record.
             {}
           else
             raise "Could not load database configuration. No such file - #{paths["config/database"].instance_variable_get(:@paths)}"
           end
  config
end

require 'active_record'
unless ENV["ENVIRONMENT"] == 'production'
  require 'dotenv'
  Dotenv.load
  require 'logger'
  ActiveRecord::Base.logger = Logger.new('debug.log')
end

ActiveRecord::Base.establish_connection(database_configuration[ENV["ENVIRONMENT"]])
require_relative './article'
