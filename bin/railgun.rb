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
require "chronic"
include Biribiri

# Load options from config and ARGV
opts = Options.new
begin 
	opts.load_config(APP_ROOT + "/config.yaml")
rescue Exception => e
	puts e.message
	exit
end
options = opts.options
Logger.setup(options)
Logger.log.info("Railgun starting up.")

# Get logging online
Logger.log.level = options[:logging][:level]
Logger.log.debug "DEBUGGING ONLINE!"

# Setup Railgun which handles renaming
railgun = Railgun.new(options)

Logger.log.debug "Connecting to Database"
# Connect to database
ActiveRecord::Base.establish_connection(options[:database])
ActiveRecord::Base.logger = Logger.log

require "commander/import"
program :name, "radionoise"
program :description, "The post-processing script for dealing with torrents"
program :version, Biribiri::VERSION
default_command :process

global_option("--loglevel [LEVEL]", Options::DEBUG_MAP.keys, "Sets logging to LEVEL") do |level|
	Logger.log.level = Options::DEBUG_MAP[level]
	Logger.log.debug "DEBUGGING ONLINE!"
end

command :runbacklog do |c|
	c.syntax = "railgun.rb runbacklog"
	c.description = "Runs the railgun backlog"
	c.action do |args,cops|
		Logger.log.info("Processing Backlog")
		Backlog.where("expire > ?", Time.now).each do |backlog|
			railgun.process(backlog.path)
			backlog.update(runs: backlog.runs + 1)
		end
		railgun.teardown
		Logger.log.info("Railgun is done! Shutting down. ビリビリ.")
	end
end

command :process do |c|
	c.syntax = "railgun.rb process"
	c.description = "Manually processes files through railgun"
	c.option "--[no-]mylist", "Adds files to mylist. Default is set in config"
	c.option "--[no-]rename", "Renames files. Default is set in config"
	c.option "--[no-]sort", "Rename only. Do not sort files"
	c.option "--backlog [DATE]", "Sets a backlog to expire at date"
	c.option "-t", "--test", "Test mode"
	c.action do |args, cops|
		if not cops.sort
			options[:renamer][:animebase] = nil
			options[:renamer][:moviebase] = nil
		end

		if cops.test
			options[:testmode] = true
		end

		if cops.mylist
			options[:mylist][:enabled] = cops.mylist
		end

		if cops.rename
			options[:renamer][:enabled] = cops.sort
		end

		if cops.backlog
			options[:backlog][:set] = Chronic.parse(cops.date)
			unless options[:backlog][:set]
				puts "Invaid setbacklog expire time."
				railgun.teardown
				exit
			end

			unless options[:backlog][:set] > Time.now
				puts "Expire time can't be in the past."
				railgun.teardown
				exit
			end
		end

		Logger.log.info("Processing command line files")

		railgun.process(args)

		railgun.teardown
		Logger.log.info("Railgun is done! Shutting down. ビリビリ.")
	end
end
