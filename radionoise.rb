#!/usr/bin/env ruby
# encoding: UTF-8

require "logger"
require "bundler"
Bunder.setup(:default)
require "active_record"

$:.unshift File.dirname(__FILE__) + "/lib"

require "transmission_api"
require "options"
require "helpers"
require "logger_ext"
require "railgun"

Dir[File.dirname(__FILE__) + '/lib/db/*.rb'].each {|file| require file }

STATUS_MAP = {
	0 => "stopped",
	1 => "check pending",
	2 => "checking",
	3 => "download pending",
	4 => "downloading",
	5 => "seed pending",
	6 => "seeding"
}

# Only allow add and cron modes, this script really shouldn't be called
# from a person so it's quite unfriendly
unless ["add", "cron"].include? ARGV[1]
	puts "Usage #{$0} [add|cron]"
end

# Start Logging
Logger.setup(STDOUT)

# Load options from Config
opts = Options.new
opts.load_config(File.expand_path("../config.yaml", __FILE__))
options = opts.options

Logger.log.level = options[:logging][:level]

railgun = Railgun.new(options)

tc = TransmissionApi.new(
	:username => options[:transmission][:username],
	:password => options[:transmission][:password],
	:url => options[:transmission][:url])

tc.fields.push("hashString", "status", "percentDone", "downloadDir")
tc.fields.delete("files")

Logger.info("Setup Transmission to #{options[:transmission][:url]}")

Logger.log.debug "Connecting to Database"
# Connect to database
ActiveRecord::Base.establish_connection(options[:database])
ActiveRecord::Base.logger = Logger.log

# Define: 
# Done torrent => 100%
# Finished torrent => 100% and (0.5 ratio OR 24 hours after completeddate)

# Path is always downloadDir + name

# Finished:
# Criteria:
# => isFinished == true OR 24 hours after doneDate OR status == 0
# => percentDone == 1
# Effects
# => Copy to unsorted if hash doesn't exist in database
# => Run railgun on filename in storage
# => Remove hash from database

# percentDone => double (1 if files are transferred)
# status => number (see status_map)
# isFinished => boolean (has reached ratio limit)

if ARGV[1] == "add"
	# Get information on torrent from hash
	thash = ENV["TR_TORRENT_HASH"] or ARGV[2]
	unless thash
		Logger.log.fatal("You must pass a hash in $TR_TORRENT_HASH or ARGV[2]")
		exit(1)
	end

	torrent = tc.find(thash)
	unless torrent
		Logger.log.fatal("Torrent Hash #{thash} not found")
		exit(1)
	end

	# Check if the Hash is Anime (based on path, set in config)
	unless torrent.downloadDir.scan(/anime/)
		Logger.log.fatal("Torrent #{torrent.name} is not anime")
		exit(1)
	end

	# Copy the file to "Unsorted" folder
	fullpath = torrent.downloadDir + torrent.name
	FileUtils.cp_r(filepath, options[:renamer][:unsorted])
	Logger.log.info("Copied #{filepath} to #{options[:renamer][:unsorted]}")	

	# Glob and run "Railgun" on it
	globpath = "#{torrent.downloadDir}/#{torrent.name}"
	globpath.gsub!(/([\[\]\{\}\*\?\\])/, '\\\\\1')
	allglob = Dir.glob(globpath, File::FNM_CASEFOLD) + Dir.glob(globpath + "/**/*.{mkv,mp4,avi}", File::FNM_CASEFOLD)
	allglob.each do |path|
		puts path
	end

	# Add hash to torrents tabled, marking copied = true
	dbrow = Torrents.where(hash: torrent.hashString).first_or_create
	dbrow.name = torrent.name
	dbrow.copied = true
	dbrow.save

elsif ARGV[1] == "cron"
	# Run Railgun on all video files in "Unsorted" folder
	# Copy any torrent that's done and not copied to "Unsorted" folder
	# Delete any torrent that's "completed" and "copied"
	# Remove hash from database so torrent can be redownloaded again
end

railgun.teardown
Logger.log.info("Radio Noise (欠陥電気) is done! Shutting down. ビリビリ.")