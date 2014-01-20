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
require "terminal-table"
include Biribiri


opts = Options.new
begin 
	opts.load_config(APP_ROOT + "/config.yaml")
rescue Exception => e
	puts e.message
	exit
end
options = opts.options
Logger.setup(options)

# Get logging online
Logger.log.level = options[:logging][:level]
Logger.log.debug "DEBUGGING ONLINE!"

Logger.log.debug "Connecting to Database"
# Connect to database
ActiveRecord::Base.establish_connection(options[:database])
ActiveRecord::Base.logger = Logger.log

require "commander/import"
program :name, "dbtool"
program :description, "Database maintance tool for those who are lazy"
program :version, VERSION

command :list do |c|
	c.syntax = "dbtool.rb list"
	c.description = "Lists torrents and current backlogs"
	c.option "--all", "Lists all backlogs, even expired ones."
	c.option "--notrunc", "Doesn't truncate filenames in the middle."
	c.action do |args, options|
		scope = (options.all ? Backlog.all : Backlog.where("expire > ?", Time.now))
		backlog_rows = scope.map do |row|
			path = File.basename(row.path)
			path = Helpers.middletrunc(path) unless options.notrunc
			[row.id, path, row.expire, row.added, row.runs]
		end
		puts Terminal::Table.new(
			:title => "Backlog", 
			:headings => ["ID", "Path", "Expires", "Added", "Runs"], 
			:rows => backlog_rows)

		puts "\n\n"

		torrent_rows = Torrents.all.map do |row|
			[row.id, row.hash_string, row.name, row.copied?]
		end

		puts Terminal::Table.new( 
			:title => "Torrents", 
			:headings => ["ID", "Hash", "Name", "Copied?"],
			:rows => torrent_rows)
	end
end
