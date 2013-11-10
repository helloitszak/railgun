require "biribiri/processor"
class Biribiri::MyListAdder < Biribiri::Processor::Plugin
	attr_accessor :watched
	attr_accessor :update
	def initialize(watch=false, update=true)
		@watched = watch
		@update = update
		Logger.log.debug("[MyList] Plugin initialized. Adding files with Watched State: #{watched.to_s}")
	end

	def process(processor, info)
		processor.mutex.synchronize do
			fid = info[:file][:fid]
			if processor.testmode
				Logger.log.info("[MyList] Would add #{info[:file][:anime][:romaji_name]} (EP: #{info[:file][:anime][:epno]}, LID: TEST, FID: #{info[:file][:fid]})")
			else
				# This is bad design, but it's AniDB's API's fault.
				# There is no obvious way to add or edit with one command.
				result, id = processor.anidb.mylist_add(fid, false, (@watched ? 1 : 0))
				case result
				when :added
					Logger.log.info("[MyList] Added #{info[:file][:anime][:romaji_name]} (EP: #{info[:file][:anime][:epno]}, LID: #{id}, FID: #{info[:file][:fid]})")
				when :exists
					if @update
						er, eid = processor.anidb.mylist_add(fid, true, (@watched ? 1 : 0))
						if er == :edited
							Logger.log.info("[MyList] Edited #{info[:file][:anime][:romaji_name]} (EP: #{info[:file][:anime][:epno]}, FID: #{info[:file][:fid]})")
						end
					else
						Logger.log.info("[MyList] File Exists. Configured not to edit. #{info[:file][:anime][:romaji_name]} (EP: #{info[:file][:anime][:epno]}, FID: #{info[:file][:fid]})")
					end
				end
			end
		end
	end
end
