require "biribiri/processor"
require "biribiri/renamers/xbmc_renamer"

class Biribiri::Railgun < Biribiri::Processor
	def initialize(config)
		super()
		@options = config

		@testmode = config[:testmode]
		@animebase = config[:renamer][:animebase]
		@moviebase = config[:renamer][:moviebase]

		@anidb_server = config[:anidb][:server]
		@anidb_port = config[:anidb][:port]
		@anidb_remoteport = config[:anidb][:remoteport]
		@anidb_username = config[:anidb][:username]
		@anidb_password = config[:anidb][:password]
		@anidb_nat = config[:anidb][:nat]

		@renamer = XbmcRenamer

		@backlog_set = config[:backlog][:set]

		setup
	end
end