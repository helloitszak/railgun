require "optparse"
require "logger"
require "yaml"
require_relative './helpers.rb'

class Options
	attr_reader :options

	DEBUG_MAP = {
		:fatal => Logger::FATAL,
		:error => Logger::ERROR,
		:warn => Logger::WARN,
		:info => Logger::INFO,
		:debug => Logger::DEBUG 	
	}

	def initialize
		@options = {}
		@options[:testmode] = false
		@options[:logging] = {}
		@options[:logging][:level] = Logger::INFO

		@options[:renamer] = {}
		@options[:renamer][:animebase] = nil
		@options[:renamer][:moviebase] = nil

		@options[:database] = {}

		@options[:anidb] = {}
	end

	def load_config(file)
		config = YAML.load(File.read(file)).deep_symbolize_keys
		@options.deep_merge!(config)
	end

	def parse!(args)
		OptionParser.new do |opts|
			opts.banner = "Usage: #{$0} [options] files"
			# This is a future feature idea, since I don't use it yet, it's not done.
			#opts.on("-m", "--[no-]mylist", "Adds files to MyList") do |m|
			#	options.mylist = m
			#end

			opts.on("-t", "--[no-]test", "Test Mode (don't move files)") do |t|
				options[:testmode] = t
			end

			opts.on("--animebase [BASEPATH]", "Puts anime in sub directories based on their name relative to base") do |base|
				options[:renamer][:animebase] = base
			end

			opts.on("--moviebase [BASEPATH]", "Puts movies in sub directories based on their name relative to base") do |base|
				options[:renamer][:moviebase] = base
			end

			opts.on("--loglevel [LEVEL]", DEBUG_MAP.keys, "Sets logging to LEVEL") do |debug|
				options[:logging][:level] = DEBUG_MAP[debug]
			end

			opts.on_tail("-h", "--help", "Show this message") do
				puts opts
				exit
			end

		end.parse!(args)
		options
	end
end 