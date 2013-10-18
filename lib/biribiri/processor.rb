require 'fileutils'
require 'thread'
require "net/anidbudp"
class Biribiri::Processor
	attr_accessor :log, :testmode
	attr_accessor :anidb_server, :anidb_port, :anidb_remoteport, :anidb_username, :anidb_password, :anidb_nat
	attr_accessor :plugins
	attr_reader :anidb

	FILE_FFIELDS = [ :aid, :eid, :gid, :length, :quality, :video_resolution,
					 :source, :sub_language, :dub_language, :video_codec,
					 :audio_codec_list, :crc32, :state, :file_type ]

	FILE_FSTATES = {
		:crcok      => 1,
		:crcerr     => 2,
		:version2   => 4,
		:version3   => 8,
		:version4   => 16,
		:version5   => 32,
		:uncensored => 64,
		:censored   => 128
	}

	VERSION_MAP = {
		:version2 => 2,
		:version3 => 3,
		:version4 => 4,
		:version5 => 5
	}

	class Plugin
		def self.ed2k(processor, info)
			Logger.log.debug("[Plugin] No ed2k hook specified.")
		end

		def self.info(processor, info)
			Logger.log.debug("[Plugin] No info hook specified.")
		end

		def self.process(processor, info)
			Logger.log.debug("[Plugin] No process hook specified.")
		end
	end

	def initialize
		@plugins = []
	end

	def setup
		# setup queues
		@ed2k_queue = Queue.new
		@info_queue = Queue.new
		@process_queue = Queue.new

		@anidb = Net::AniDBUDP.new(@anidb_server, @anidb_port, @anidb_remoteport)
		@anidb.connect(@anidb_username, @anidb_password, @anidb_nat)

		if @testmode
			Logger.log.info("[#] Running in test mode. Files won't be renamed.")
		end

		@ed2k_worker = Thread.new do
			while true
				Logger.log.debug("[H] Waiting for next file to hash")

				# Get the next file, stopping the queue if nil is recieved.
				file = @ed2k_queue.pop
				break unless file
				
				Logger.log.debug("[H] Hashing #{File.basename(file)}")
				
				size, hash = Net::AniDBUDP.ed2k_file_hash(file)
				
				info = { :size => size, :hash => hash, :file => file }
				call_plugin_stack(:ed2k, info)
				@info_queue << info

				Logger.log.info("[H] #{File.basename(file)} (H: #{hash}, S: #{size})")
			end

			# Tell the next processor that we're done sending it things
			@info_queue << nil
		end

		@info_worker = Thread.new do
			while true
				Logger.log.debug("[I] Waiting for next file to get info")
				src = @info_queue.pop
				break unless src
				Logger.log.debug("[I] Searching #{File.basename(src[:file])}")
				file = @anidb.search_file(File.basename(src[:file]), src[:size], src[:hash], FILE_FFIELDS)
				if file.nil?
					Logger.log.warn("[I] #{src[:file]} can't be found. ed2k://|file|#{File.basename(src[:file])}|#{src[:size]}|#{src[:hash]}|/")
					next
				end
				Logger.log.info("[I] #{File.basename(src[:file])} => #{file[:anime][:romaji_name]} (EP: #{file[:anime][:epno]}, FID: #{file[:fid]}, AID: #{file[:file][:aid]})")

				# Extract the states variable into something more sane
				# Ryan Bates please bear my children
				state_keys = FILE_FSTATES.reject { |k,v| ((file[:file][:state].to_i || 0) & v).zero? }.keys
				file[:file][:state_keys] = state_keys

				file[:file][:crcstatus] = (state_keys & [:crcok, :crcerr]).first
				file[:file][:censoredstatus] = (state_keys & [:uncensored, :censored]).first

				# This is kinda gross, but it works.
				# Coded to get the maximum version provided in case of brain damage
				version = (state_keys & [:version2, :version3, :version4, :version5]).map { |i| VERSION_MAP[i] }.max
				file[:file][:version] = version || 1

				info = {:src => src, :file => file}
				call_plugin_stack(:info, info)
				@process_queue << info

				Logger.log.debug("[I] Added #{File.basename(src[:file])} to process queue")
			end
			@process_queue << nil
		end

		@process_worker = Thread.new do
			# All that's left is to rename or print
			while true
				Logger.log.debug("[P] Waiting for next file to process")
				file = @process_queue.pop
				break unless file
				Logger.log.debug("[P] Processing #{File.basename(file[:src][:file])}")

				call_plugin_stack(:process, file)
			end	
		end

		Logger.log.info("Workers are up and waiting.")
	end

	def process(files)
		files = [files] if files.is_a? String
		files.each do |file|
			if File.file?(file)
				@ed2k_queue << file
				Logger.log.info("[F] Added #{file} to queue")
			end
		end
	end

	def teardown
		@ed2k_queue << nil
		[@ed2k_worker, @info_worker, @process_worker].each(&:join)
		@anidb.logout
	end

	private
	def call_plugin_stack(method_name, param)
		@plugins.each do |plugin|
			if plugin.respond_to?(method_name)
				Logger.log.debug("Called plugin #{plugin}::#{method_name.to_s}(#{param})")
				plugin.send(method_name, self, param)
			end
		end
	end
end
