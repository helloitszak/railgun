require "optparse"
require "logger"
require "yaml"
require "chronic"
require "active_support/core_ext/hash"

class Biribiri::Options
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

		@options[:backlog] = {}
		@options[:backlog][:run] = false 
		@options[:backlog][:set] = false

		@options[:database] = {}

		@options[:anidb] = {}

		@options[:mylist] = {}

		@options[:radionoise] = {}
	end

	def load_config(file)
		unless File.exists?(file)
			raise "Config file #{file} not found."
		end
		config = YAML.load(File.read(file)).deep_symbolize_keys
		
		if config[:logging] and config[:logging][:level]
			config[:logging][:level] = DEBUG_MAP[config[:logging][:level].to_sym]
		end

		if config[:database] and config[:database][:adapter] == "sqlite3" and config[:database][:database]
			config[:database][:database] = File.expand_path(config[:database][:database], (APP_ROOT or "."))
		end
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

			opts.on("--setbacklog [DATE]", "Adds to the backlog to expire at DATE using Chronic") do |date|
				options[:backlog][:set] = Chronic.parse(date)
				unless options[:backlog][:set]
					puts "Invaid setbacklog expire time."
					exit
				end

				unless options[:backlog][:set] > Time.now
					puts "Expire time can't be in the past."
					exit
				end
			end

			opts.on("--runbacklog", "Runs the backlog") do |backlog|
				options[:backlog][:run] = backlog
			end

			opts.on_tail("-h", "--help", "Show this message") do
				puts opts
				exit
			end

		end.parse!(args)
		options
	end
end