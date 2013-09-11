#!/usr/bin/env ruby
# encoding: UTF-8

require "logger"
require "bundler"
Bundler.setup(:default)
require "active_record"

$:.unshift File.dirname(__FILE__) + "/lib"

require "net/anidbudp"
require "options"
require "helpers"
require "logger_ext"
require "railgun"

Dir[File.dirname(__FILE__) + '/lib/db/*.rb'].each {|file| require file }

# TODO: Add ability to pick log destination.
Logger.setup(STDOUT)

# Load options from config and ARGV
opts = Options.new
opts.load_config(File.expand_path("../config.yaml", __FILE__))
opts.parse!(ARGV)
options = opts.options

# Get logging online
Logger.log.level = options[:logging][:level]
Logger.log.debug "DEBUGGING ONLINE!"

# Setup Railgun which handles renaming
railgun = Railgun.new(options)

if options[:backlog][:run] or options[:backlog][:set]
	Logger.log.debug "Connecting to Database"
	# Connect to database
	ActiveRecord::Base.establish_connection(options[:database])
	ActiveRecord::Base.logger = Logger.log
end

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