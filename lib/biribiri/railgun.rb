require "biribiri/processor"
require "biribiri/plugins/xbmc_renamer"
require "biribiri/plugins/mylist_adder"

class Biribiri::Railgun < Biribiri::Processor
	def initialize(config)
		super(config[:anidb], config[:testmode])

		xbmcrenamer = XbmcRenamer.new(config[:renamer][:animebase], config[:renamer][:moviebase])
		xbmcrenamer.backlog_set = config[:backlog][:set]

		if config[:renamer][:enabled]
			@plugins << xbmcrenamer
		end

		if config[:mylist][:enabled]
			@plugins << MyListAdder.new(false, false)
		end

		setup
	end
end