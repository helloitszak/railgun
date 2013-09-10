#!/usr/bin/env ruby
# encoding: UTF-8

require "logger"
require "bundler"
Bundler.setup(:default)
require "active_record"

require_relative "./lib/net/anidbudp.rb"
require_relative "./lib/options.rb"
require_relative "./lib/processor.rb"
require_relative "./lib/helpers.rb"
require_relative "./lib/logger.rb"
require_relative "./lib/renamers/xbmc_renamer.rb"

Dir[File.dirname(__FILE__) + '/lib/db/*.rb'].each {|file| require file }

# TODO: Add ability to pick log destination.
Logger.setup(STDOUT)

proc = Processor.new

opts = Options.new
opts.load_config(File.expand_path("../config.yaml", __FILE__))
opts.parse!(ARGV)

# Get the options from ARGV
options = opts.options

Logger.log.level = options[:logging][:level]

proc.testmode = options[:testmode]
proc.animebase = options[:renamer][:animebase]
proc.moviebase = options[:renamer][:moviebase]

proc.anidb_server = options[:anidb][:server]
proc.anidb_port = options[:anidb][:port]
proc.anidb_remoteport = options[:anidb][:remoteport]
proc.anidb_username = options[:anidb][:username]
proc.anidb_password = options[:anidb][:password]
proc.anidb_nat = options[:anidb][:nat]

proc.renamer = XbmcRenamer

proc.backlog_set = options[:backlog][:set]

Logger.log.debug "DEBUGGING ONLINE!"

if options[:backlog][:run] or options[:backlog][:set]
	Logger.log.debug "Connecting to Database"
	# Connect to database
	ActiveRecord::Base.establish_connection(options[:database])
	ActiveRecord::Base.logger = Logger.log
end

Logger.log.debug "Options: #{options.to_s}"

# Start up the Processor Queues
proc.setup

if options[:backlog][:run]
	Logger.log.info("Processing Backlog")
	Backlog.where("expire > ?", Time.now).each do |backlog|
		proc.process(backlog.path)
		backlog.update(runs: backlog.runs + 1)
	end
end

if not ARGV.empty?
	Logger.log.info("Processing command line files")
	proc.process(ARGV)
end

# This blocks until the queues are done.
proc.teardown

Logger.log.info("Railgun is done! Shutting down. ビリビリ.")