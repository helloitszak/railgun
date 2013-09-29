require 'logger'
require 'gelf'
require 'pp'

class ProxyLogger
	attr_reader :loggers

	def initialize
		@loggers = []
	end

	def method_missing(name, *args, &block)
		@loggers.each do |logger|
			logger.send(name, *args, &block)
		end
	end
end

class Logger
	class << self
		def setup(config)
			@@logger = ProxyLogger.new
			@@logger.loggers << Logger.new(STDOUT)
			if config[:logging][:destinations]
				config[:logging][:destinations].each do |dest|
					dest.each_pair do |type, args|
						case type
						when "file"
							@@logger.loggers << Logger.new(args)
						when "gelf"
							@@logger.loggers << GELF::Logger.new(args["host"], args["port"], "WAN", { :facility => "biribiri" })
						else
							puts "Logger #{type} not defined"
						end
					end
				end
			end
			@@logger.level = Logger::INFO
		end

		def log
			@@logger
		end
	end
end

