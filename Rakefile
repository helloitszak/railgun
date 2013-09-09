require 'active_record'
require 'yaml'
require 'logger'


task :migrate => :enviornment do 
	ActiveRecord::Migrator.migrate("db/migrate", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
end

task :enviornment do
	ActiveRecord::Base.establish_connection(YAML.load(File.read(File.expand_path("../config.yaml", __FILE__)))["database"])
	ActiveRecord::Base.logger = Logger.new(STDOUT)
end