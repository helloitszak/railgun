#!/usr/bin/env ruby
# encoding: UTF-8

require "logger"
require_relative "./lib/net/anidbudp.rb"
require_relative "./lib/options.rb"
require_relative "./lib/processor.rb"


log = Logger.new(STDOUT)

proc = Processor.new

opts = Options.new
opts.parse!(ARGV)

# Get the options from ARGV
options = opts.options

log.level = options[:logging][:level]

proc.testmode = options[:renamer][:testmode]
proc.animebase = options[:renamer][:animebase]
proc.moviebase = options[:renamer][:moviebase]

# proc.anidb_server = options[:anidb][:server]
# proc.anidb_port = options[:anidb][:port]
# proc.anidb_remoteport = options[:anidb][:remoteport]
# proc.anidb_username = options[:anidb][:username]
# proc.anidb_password = options[:anidb][:password]
# proc.anidb_nat = options[:anidb][:nat]

# TODO: Change this when I make the logging static
proc.log = log


log.debug "WE DEBUGGING NOW!"
log.debug options.to_s

exit

def truncate(s, length = 30, ellipsis = '…')
	if s.length > length
		s.to_s[0..length].gsub(/[^\w]\w+\s*$/, ellipsis)
	else
		s
	end
end

SPECIAL_MAP = {
	"S" => "S",
	"C" => "S1",
	"T" => "S2",
	"P" => "S3",
	"O" => "S4"
}

proc.renamer do |file|
	episode_title = [file[:anime][:ep_english_name], file[:anime][:ep_romaji_name]].find {|x| not x.nil?}

	# Show Title
	show_title = [file[:anime][:romaji_name], file[:anime][:english_name]].find {|x| not x.nil?}
	show_title.gsub!(/[\\\":\/*|<>?]/, " ")
	show_title.gsub!(/\s+/, " ")
	show_title.gsub!(/^\s|\s$/, "")
	show_title.gsub!(/`/, "'")

	# Episode Title
	episode_title = [file[:anime][:ep_english_name], file[:anime][:ep_romaji_name]].find {|x| not x.nil?}
	episode_title.gsub!(/[\\\":\/*|<>?]/, " ")
	episode_title.gsub!(/\s+/, " ")
	episode_title.gsub!(/^\s|\s$/, "")
	episode_title.gsub!(/`/, "'")
	episode_title = truncate(episode_title, 64)

	# Episode Number
	regular = ""
	special = "S"
	seperator = " - "

	specialtag = file[:anime][:epno].gsub(/[1234567890]/, "")
	padlength = (specialtag.empty? ? file[:anime][:highest_episode_number].to_s.length : 2)

	# The to_i.to_s is to strip leading 0s from the episode number
	episodeno = file[:anime][:epno].gsub(/[SCTPO]/, "").to_i.to_s.rjust(padlength, "0")
	version = (file[:file][:version] == 1 ? "" : "v#{file[:file][:version]}")

	specialno = (SPECIAL_MAP.include?(specialtag) ? SPECIAL_MAP[specialtag] : "")
	fullepno = [" - ", specialno, episodeno, version, " - "] * ""

	# File info
	group = "[#{[file[:anime][:group_short_name], file[:anime][:group_name]].find {|x| not x.nil?}}]"
	src = "[#{file[:file][:source].gsub("Blu-ray", "BluRay")}]"
	cen = file[:censoredstatus] ? "[Cen]" : ""
	res = "[#{file[:file][:video_resolution]}]"
	vcodec = "[#{file[:file][:video_codec].gsub("H264/AVC", "h264")}]"
	acodec = "[#{file[:file][:audio_codec_list]}]"
	crc = "(#{file[:file][:crc32].upcase})"

	fileinfo = [" ", group, src, cen, res, vcodec, crc] * ""

	# File Name
	fullfile = case file[:anime][:type]
	when "Movie", "OVA"
		# Process Movie
		[show_title, fileinfo, ".", file[:file][:file_type]] * ""
	else
		# Process episodic
		[show_title, fullepno, episode_title, fileinfo, ".", file[:file][:file_type]] * ""
	end
end

# Now that the workers are setup, kick off the actual process
# Make sure ARGV is all files, expand paths and get sizes
proc.process(ARGV)

log.info("Railgun is done! Shutting down. ビリビリ.")