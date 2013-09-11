require 'logger'
class Logger
	class << self
		def setup(output)
			@@logger = Logger.new(output)
			@@logger.level = Logger::INFO
		end

		def log
			@@logger
		end
	end
end