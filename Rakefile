require 'active_record'
require 'yaml'
require 'logger'

$:.unshift File.dirname(__FILE__) + "/lib"

require "options"



task :migrate => :enviornment do 
	ActiveRecord::Migrator.migrate("db/migrate", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
end

task :enviornment do
	opts = Options.new
	opts.load_config(File.expand_path("../config.yaml", __FILE__))
	options = opts.options
	ActiveRecord::Base.establish_connection(options[:database])
	ActiveRecord::Base.logger = Logger.new(STDOUT)
end