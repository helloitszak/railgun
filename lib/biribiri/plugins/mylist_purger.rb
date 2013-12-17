require "biribiri/processor"
class Biribiri::MyListPurger < Biribiri::Processor::Plugin
	def initialize
		Logger.log.info("[MyList] Plugin initialized. Purging files")
		Logger.log.debug("[MyList] Args: #{@args}")
	end

	def process(processor, info)
		processor.mutex.synchronize do
			fid = info[:file][:fid]
			if processor.testmode
				Logger.log.info("[MyList] Would purge #{info[:file][:anime][:romaji_name]} (EP: #{info[:file][:anime][:epno]}, FID: #{info[:file][:fid]})")
			else
				result = anidb.mylist_del_by_fid(fid)
				if result
					Logger.log.info("[MyList] Purged #{info[:file][:anime][:romaji_name]} (EP: #{info[:file][:anime][:epno]}, FID: #{info[:file][:fid]})")
				else
					Logger.log.info("[MyList] File not found in MyList #{info[:file][:anime][:romaji_name]} (EP: #{info[:file][:anime][:epno]}, FID: #{info[:file][:fid]})")
				end
			end
		end
	end
end
