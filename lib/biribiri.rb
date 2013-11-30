module Biribiri
	VERSION = '1.0.1'
end

require 'biribiri/db/backlog'
require 'biribiri/db/torrents'
require 'biribiri/helpers'
require 'biribiri/logger_ext'
require 'biribiri/options'
require 'biribiri/processor'
require 'biribiri/railgun'
require 'biribiri/plugins/xbmc_renamer'
require 'biribiri/plugins/mylist_editor'
require 'biribiri/plugins/file_deleter'