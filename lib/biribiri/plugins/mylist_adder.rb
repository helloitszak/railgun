require "biribiri/processor"
class Biribiri::MyListAdder < Biribiri::Processor::Plugin
	def process(processor, info)
		fid = info[:file][:fid]
		if processor.testmode
			Logger.log.info("[MyList] Would add #{info[:file][:anime][:romaji_name]} (EP: #{info[:file][:anime][:epno]}, LID: TEST, FID: #{info[:file][:fid]})")
		else
			lid = processor.anidb.mylist_add(fid)
			if lid
				Logger.log.info("[MyList] Added #{info[:file][:anime][:romaji_name]} (EP: #{info[:file][:anime][:epno]}, LID: #{lid}, FID: #{info[:file][:fid]})")
			end
		end
	end
end
