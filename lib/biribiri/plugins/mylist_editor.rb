require "biribiri/processor"
class Biribiri::MyListEditor < Biribiri::Processor::Plugin
	attr_accessor :args
	attr_accessor :update
	def initialize(update=true, args = {})
		@update = update
		
		default_args = {
			:viewed => false,
			:state => :hdd,
			:source => nil,
			:storage => nil
		}
		@args = default_args.merge(args)
		Logger.log.debug("[MyList] Plugin initialized. Updating files with: #{@args}")
	end

	def process(processor, info)
		processor.mutex.synchronize do
			fid = info[:file][:fid]
			if processor.testmode
				Logger.log.info("[MyList] Would add #{info[:file][:anime][:romaji_name]} (EP: #{info[:file][:anime][:epno]}, LID: TEST, FID: #{info[:file][:fid]})")
			else
				# This is bad design, but it's AniDB's API's fault.
				# There is no obvious way to add or edit with one command.
				result, id = mylist_add(processor.anidb, fid, false)
				case result
				when :added
					Logger.log.info("[MyList] Added #{info[:file][:anime][:romaji_name]} (EP: #{info[:file][:anime][:epno]}, LID: #{id}, FID: #{info[:file][:fid]})")
				when :exists
					if @update
						edit_result, eid = mylist_add(processor.anidb, fid, true)
						if edit_result == :edited
							Logger.log.info("[MyList] Edited #{info[:file][:anime][:romaji_name]} (EP: #{info[:file][:anime][:epno]}, FID: #{info[:file][:fid]})")
						end
					else
						Logger.log.info("[MyList] Exists. Configured not to edit. #{info[:file][:anime][:romaji_name]} (EP: #{info[:file][:anime][:epno]}, FID: #{info[:file][:fid]})")
					end
				end
			end
		end
	end

	def mylist_add(anidb, fid, update)
		anidb.mylist_add(fid, update, @args[:viewed], @args[:state], @args[:source], @args[:storage])
	end
end
