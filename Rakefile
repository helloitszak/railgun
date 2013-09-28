
APP_ROOT = File.dirname(__FILE__)
ENV["BUNDLE_GEMFILE"] = APP_ROOT + "/Gemfile"
$:.unshift APP_ROOT + "/lib"

require 'active_record'
require 'yaml'
require 'logger'
require 'biribiri'



task :migrate => :enviornment do 
	ActiveRecord::Migrator.migrate("db/migrate", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
end

task :enviornment do
	opts = Biribiri::Options.new
	opts.load_config(File.expand_path("../config.yaml", __FILE__))
	options = opts.options
	ActiveRecord::Base.establish_connection(options[:database])
	ActiveRecord::Base.logger = Logger.new(STDOUT)
end