require 'fileutils'
require 'thread'
require "net/anidbudp"
class Biribiri::Processor
	attr_accessor :log, :testmode, :animebase, :moviebase, :backlog_set
	attr_accessor :anidb_server, :anidb_port, :anidb_remoteport, :anidb_username, :anidb_password, :anidb_nat
	attr_accessor :renamer

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

	class Renamer
		def self.rename(file)
			raise NotImplementedError
		end
	end

	def setup
		# setup queues
		@ed2k_queue = Queue.new
		@info_queue = Queue.new
		@process_queue = Queue.new

		if @testmode
			Logger.log.info("[#] Running in test mode. Files won't be renamed.")
		end

		# setup ed2k hash worker
		@ed2k_worker = Thread.new do
			# Go forever while we have stuff to process
			while true
				Logger.log.debug("[H] Waiting for next file to hash")
				file = @ed2k_queue.pop
				break unless file
				Logger.log.debug("[H] Hashing #{File.basename(file)}")
				size, hash = Net::AniDBUDP.ed2k_file_hash(file)
				@info_queue << { :size => size, :hash => hash, :file => file }
				Logger.log.info("[H] #{File.basename(file)} (H: #{hash}, S: #{size})")
			end

			# Tell the next processor that we're done sending it things
			@info_queue << nil
		end

		@info_worker = Thread.new do
			anidb = Net::AniDBUDP.new(@anidb_server, @anidb_port, @anidb_remoteport)
			anidb.connect(@anidb_username, @anidb_password, @anidb_nat)

			while true
				Logger.log.debug("[I] Waiting for next file to get info")
				src = @info_queue.pop
				break unless src
				Logger.log.debug("[I] Searching #{File.basename(src[:file])}")
				file = anidb.search_file(File.basename(src[:file]), src[:size], src[:hash], FILE_FFIELDS)
				if file.nil?
					Logger.log.warn("[I] #{src} can't be found. Skipping.")
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

				# Uncomment for debugging
				#pp file
				@process_queue << {:src => src, :file => file}
				Logger.log.debug("[I] Added #{File.basename(src[:file])} to process queue")
			end

			anidb.logout
			@process_queue << nil
		end

		@process_worker = Thread.new do
			# All that's left is to rename or print
			while true
				Logger.log.debug("[P] Waiting for next file to process")
				file = @process_queue.pop
				break unless file
				Logger.log.debug("[P] Processing #{File.basename(file[:src][:file])}")
				
				renamed_file = @renamer.rename(file[:file])

				if @testmode
					Logger.log.info("[P] Would rename #{File.basename(file[:src][:file])} to #{renamed_file}")
				else
					basepath = File.dirname(file[:src][:file])

					if @animebase and not ["Movie", "OVA"].include?(file[:file][:anime][:type])
						anime_name = [file[:file][:anime][:romaji_name], file[:file][:anime][:english_name]].find {|x| not x.nil?}
						basepath = @animebase + "/" + anime_name
						FileUtils.mkdir(basepath)
					end
					
					if @moviebase and ["Movie", "OVA"].include?(file[:file][:anime][:type])
						basepath = @moviebase
					end

					finalpath = File.expand_path("#{basepath}/#{renamed_file}")

					begin
						if file[:src][:file] != finalpath
							FileUtils.mv(file[:src][:file], finalpath)
							Logger.log.info("[P] Renamed #{File.basename(file[:src][:file])} to #{basepath}/#{renamed_file}")
						else
							Logger.log.warn("[P] #{File.basename(file[:src][:file])} was not renamed to itself.")
						end
					rescue
						Logger.log.error("[P] Could not rename #{file[:src][:file]}")
						Logger.log.debug($!)
					end

					original_backlog = Backlog.where(path: file[:src][:file]).first

					if original_backlog
						original_backlog.path = finalpath
						original_backlog.save
					end

					if @backlog_set
						backlog = Backlog.where(path: finalpath).first_or_create
						if backlog.added.nil?
							backlog.added = DateTime.now
						end

						backlog.expire = @backlog_set

						backlog.save
						Logger.log.info("[P] Added backlog for #{renamed_file} to expire on #{@backlog_set}")
					end
				end
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
	end
end
