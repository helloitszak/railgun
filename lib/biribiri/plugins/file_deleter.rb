require "biribiri/processor"
require "fileutils"

class Biribiri::FileDeleter < Biribiri::Processor::Plugin
	def initialize
		Logger.log.info("[FileDeleter] Plugin initialized. Deleting files.")
	end

	def process(processor, info)
		if processor.testmode
			require "pp"
			pp info
			Logger.log.info("[FileDeleter] Would delete #{info[:src][:file]}")
		else
			begin
				FileUtils.rm(info[:src][:file])
				Logger.log.info("[FileDeleter] Deleted #{info[:src][:file]}")
			rescue
				Logger.log.error("[FileDeleter] An error occured while trying to delete #{info[:src][:file]}")
			end
		end
	end
end
