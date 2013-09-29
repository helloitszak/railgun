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
include Biribiri

# TODO: Add ability to pick log destination.
# Load options from config and ARGV
opts = Options.new
opts.load_config(File.expand_path("../config.yaml", __FILE__))
opts.parse!(ARGV)
options = opts.options
Logger.setup(options)

# Get logging online
Logger.log.level = options[:logging][:level]
Logger.log.debug "DEBUGGING ONLINE!"

# Setup Railgun which handles renaming
railgun = Railgun.new(options)

Logger.log.debug "Connecting to Database"
# Connect to database
ActiveRecord::Base.establish_connection(options[:database])
ActiveRecord::Base.logger = Logger.log


Logger.log.debug "Options: #{options.to_s}"

if options[:backlog][:run]
	Logger.log.info("Processing Backlog")
	Backlog.where("expire > ?", Time.now).each do |backlog|
		railgun.process(backlog.path)
		backlog.update(runs: backlog.runs + 1)
	end
end

if not ARGV.empty?
	Logger.log.info("Processing command line files")
	railgun.process(ARGV)
end

# This blocks until the queues are done.
railgun.teardown

Logger.log.info("Railgun is done! Shutting down. ビリビリ.")