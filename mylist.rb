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
options = opts.options
Logger.setup(options)

# Get logging online
Logger.log.level = options[:logging][:level]
Logger.log.debug "DEBUGGING ONLINE!"

program :name, "mylist"
program :description, "Manages AniDB MyList"
program :version, "0.1.0"

command :add do |c|
	c.syntax = "mylist.rb add [options] <files>"
	c.description = "Adds files to MyList"
	c.option "--[no-]viewed", "Set whether the file is viewed or not, defaults to not."
	c.action do |args, options|
		#TODO: Implementation
	end
end