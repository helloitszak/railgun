require "biribiri/processor"
require "biribiri/plugins/xbmc_renamer"
require "biribiri/plugins/mylist_adder"

class Biribiri::Railgun < Biribiri::Processor
	def initialize(config)
		super()
		@options = config

		@testmode = config[:testmode]

		@anidb_server = config[:anidb][:server]
		@anidb_port = config[:anidb][:port]
		@anidb_remoteport = config[:anidb][:remoteport]
		@anidb_username = config[:anidb][:username]
		@anidb_password = config[:anidb][:password]
		@anidb_nat = config[:anidb][:nat]

		xbmcrenamer = XbmcRenamer.new(config[:renamer][:animebase], config[:renamer][:moviebase])
		xbmcrenamer.backlog_set = config[:backlog][:set]
		@plugins << xbmcrenamer

		if config[:renamer][:mylist]
			@plugins << MyListAdder.new
		end

		setup
	end
end