#!/usr/bin/env ruby
# encoding: UTF-8

require "logger"
require "bundler"
Bundler.setup(:default)
require "active_record"
require "date"

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

GLOB_FILETYPES = "mkv,avi,mp4"

# Only allow add and cron modes, this script really shouldn't be called
# from a person so it's quite unfriendly
unless ["add", "cron"].include? ARGV[0]
	puts "Usage #{$0} [add|cron]"
end

# Start Logging
Logger.setup(STDOUT)

# Load options from Config
opts = Options.new
opts.load_config(File.expand_path("../config.yaml", __FILE__))
options = opts.options
options[:backlog][:set] = (DateTime.now + 7)

Logger.log.level = options[:logging][:level]

railgun = Railgun.new(options)

tc = TransmissionApi.new(
	:username => options[:transmission][:username],
	:password => options[:transmission][:password],
	:url => options[:transmission][:url])

tc.fields.push("hashString", "status", "percentDone", "downloadDir")
tc.fields.delete("files")

Logger.log.info("Setup Transmission to #{options[:transmission][:url]}")

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

if ARGV[0] == "add"
	# Get information on torrent from hash
	thash = (ENV["TR_TORRENT_HASH"] or ARGV[1])
	unless thash
		Logger.log.fatal("You must pass a hash in $TR_TORRENT_HASH or ARGV[1]")
		exit(1)
	end

	torrent = tc.find(thash)
	unless torrent
		Logger.log.fatal("Torrent Hash #{thash} not found")
		exit(1)
	end

	# Check if the Hash is Anime (based on path, set in config)
	if torrent["downloadDir"].scan(/anime/).empty?
		Logger.log.fatal("Torrent #{torrent["name"]} is not anime")
		exit(1)
	end

	# Copy the file to "Unsorted" folder
	fullpath = torrent["downloadDir"] + "/" + torrent["name"]
	FileUtils.cp_r(fullpath, options[:renamer][:unsorted])
	Logger.log.info("Copied #{fullpath} to #{options[:renamer][:unsorted]}")	

	# Glob and run "Railgun" on it
	Logger.log.info("Running Railgun on Torrent")
	globpath = "#{options[:renamer][:unsorted]}/#{torrent["name"]}"
	globpath.gsub!(/([\[\]\{\}\*\?\\])/, '\\\\\1')
	allglob = Dir.glob(globpath, File::FNM_CASEFOLD) + Dir.glob(globpath + "/**/*.{#{GLOB_FILETYPES}}", File::FNM_CASEFOLD)
	files = allglob.select { |f| File.file?(f) }
	railgun.process(files)

	# Add hash to torrents tabled, marking copied = true
	Logger.log.info("Marking torrent as done")
	dbrow = Torrents.where(hash_string: torrent["hashString"]).first_or_create
	dbrow.name = torrent["name"]
	dbrow.copied = true
	dbrow.save

elsif ARGV[0] == "cron"
	# Run Railgun on all video files in "Unsorted" folder (this catches files never had info)
	Logger.log.info("Processing #{options[:renamer][:unsorted]}")
	globpath = options[:renamer][:unsorted]
	globpath.gsub!(/([\[\]\{\}\*\?\\])/, '\\\\\1')
	files = Dir.glob(globpath + "/**/*.{#{GLOB_FILETYPES}}", File::FNM_CASEFOLD).select { |f| File.file?(f) }
	railgun.process(files)

	# Copy any torrent that's done and not copied to "Unsorted" folder
	Logger.log.info("Copying all \"done\" and \"uncopied\" torrents")
	donetorrents = tc.all.select { |torrent| torrent["percentDone"] == 1 and not torrent["downloadDir"].scan(/anime/).empty? }
	donetorrents.each do |torrent|
		trow = Torrents.find_by hash_string: torrent["hashString"]
		if trow.nil? or trow.copied? == false
			# hahaha what the fuck is DRY
			# Copy the file to "Unsorted" folder
			fullpath = torrent["downloadDir"] + "/" + torrent["name"]
			FileUtils.cp_r(fullpath, options[:renamer][:unsorted])
			Logger.log.info("Copied #{fullpath} to #{options[:renamer][:unsorted]}")	

			# Glob and run "Railgun" on it
			Logger.log.info("Running Railgun on Torrent")
			globpath = "#{options[:renamer][:unsorted]}/#{torrent["name"]}"
			globpath.gsub!(/([\[\]\{\}\*\?\\])/, '\\\\\1')
			allglob = Dir.glob(globpath, File::FNM_CASEFOLD) + Dir.glob(globpath + "/**/*.{#{GLOB_FILETYPES}}", File::FNM_CASEFOLD)
			files = allglob.select { |f| File.file?(f) }
			railgun.process(files)
			trow.copied = true
			trow.save
		end
	end

	# Delete any torrent that's "completed" and "copied"
	Logger.log.info("Deleting \"completed\" and \"copied\" torrents")
	completedtorrents = tc.all.select do |torrent|
		(torrent["isFinished"] == true or torrent["status"] == 0) and not torrent["downloadDir"].scan(/anime/).empty?
	end
	completedtorrents.each do |torrent|
		trow = Torrents.find_by hash_string: torrent["hashString"]
		if trow.copied?
			Logger.log.info("Removed #{torrent["downloadDir"]}/#{torrent["name"]}")
			FileUtils.rm_r("#{torrent["downloadDir"]}/#{torrent["name"]}")		

			# Remove hash from database so torrent can be redownloaded again
			Logger.log.info("Removed #{torrent["hashString"]} from database")		
			trow.destroy
		end
	end
end

railgun.teardown
Logger.log.info("Radio Noise (欠陥電気) is done! Shutting down. ビリビリ.")
