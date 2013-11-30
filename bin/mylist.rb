#!/usr/bin/env ruby
# encoding: UTF-8
APP_ROOT = File.dirname(__FILE__) + "/../"
ENV["BUNDLE_GEMFILE"] = APP_ROOT + "/Gemfile"
$:.unshift APP_ROOT + "/lib"

require "bundler"
Bundler.setup(:default)
require "logger"
require "active_record"
require "biribiri"
include Biribiri

opts = Options.new
begin 
	opts.load_config(APP_ROOT + "/config.yaml")
rescue Exception => e
	puts e.message
	exit
end
Logger.setup(opts.options)

# Get logging online
Logger.log.level = opts.options[:logging][:level]
Logger.log.debug "DEBUGGING ONLINE!"

require "commander/import"
program :name, "mylist"
program :description, "Manages AniDB MyList"
program :version, VERSION

global_option('--test', "Pretends to add the file to MyList")
global_option("--loglevel [LEVEL]", Options::DEBUG_MAP.keys, "Sets logging to LEVEL") do |level|
	Logger.log.level = Options::DEBUG_MAP[level]
	Logger.log.debug "DEBUGGING ONLINE!"
end

command :add do |c|
	c.syntax = "mylist.rb add [options] <files>"
	c.description = "Adds files to MyList. Note: it won't update unless an modification parameter is specified."
	c.option "--[no-]viewed", "Set whether the file is viewed or not, defaults to not."
	c.action do |args, options|
		edit = (not options.viewed.nil?)
		# Setup processor to run mylist additions
		processor = Processor.new(opts.options[:anidb], options.test)
		processor.plugins << MyListEditor.new(edit, :viewed => options.viewed)

		processor.setup
		processor.process(args)
		processor.teardown
	end
end