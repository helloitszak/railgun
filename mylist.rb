#!/usr/bin/env ruby
# encoding: UTF-8
APP_ROOT = File.dirname(__FILE__)
ENV["BUNDLE_GEMFILE"] = APP_ROOT + "/Gemfile"
$:.unshift APP_ROOT + "/lib"

require "bundler"
Bundler.setup(:default)
require "logger"
require "active_record"
require "biribiri"
require "commander/import"
include Biribiri

opts = Options.new
opts.load_config(File.expand_path("../config.yaml", __FILE__))
Logger.setup(opts.options)

# Get logging online
Logger.log.level = opts.options[:logging][:level]
Logger.log.debug "DEBUGGING ONLINE!"

program :name, "mylist"
program :description, "Manages AniDB MyList"
program :version, "0.1.0"

global_option('--test', "Pretends to add the file to MyList")
global_option("--loglevel [LEVEL]", Options::DEBUG_MAP.keys, "Sets logging to LEVEL") do |level|
	Logger.log.level = Options::DEBUG_MAP[level]
	Logger.log.debug "DEBUGGING ONLINE!"
end

command :add do |c|
	c.syntax = "mylist.rb add [options] <files>"
	c.description = "Adds files to MyList"
	c.option "--[no-]viewed", "Set whether the file is viewed or not, defaults to not."
	c.action do |args, options|
		options.viewed ||= false
		# Setup processor to run mylist additions
		processor = Processor.new(opts.options[:anidb], options.test)
		processor.plugins << MyListAdder.new(options.viewed)

		processor.setup
		processor.process(args)
		processor.teardown
	end
end