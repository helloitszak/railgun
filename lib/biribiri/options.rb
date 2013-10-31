require "optparse"
require "logger"
require "yaml"
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
end