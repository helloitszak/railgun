require 'fileutils'
require 'thread'
class Processor
	attr_accessor :log, :testmode, :animebase, :moviebase
	attr_accessor :anidb_server, :anidb_port, :anidb_remoteport, :anidb_username, :anidb_password, :anidb_nat
	attr_reader :renamer

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

	def renamer(&block)
		@renamer = block
	end


	def process(files)
		# setup queues
		ed2k_queue = Queue.new
		info_queue = Queue.new
		process_queue = Queue.new

		if @testmode
			@log.info("[#] Running in test mode. Files won't be renamed.")
		end

		# setup ed2k hash worker
		ed2k_worker = Thread.new do
			# Go forever while we have stuff to process
			while true
				@log.debug("[H] Waiting for next file to hash")
				file = ed2k_queue.pop
				break unless file
				@log.debug("[H] Hashing #{File.basename(file)}")
				size, hash = Net::AniDBUDP.ed2k_file_hash(file)
				info_queue << { :size => size, :hash => hash, :file => file }
				@log.info("[H] #{File.basename(file)} (H: #{hash}, S: #{size})")
			end

			# Tell the next processor that we're done sending it things
			info_queue << nil
		end

		info_worker = Thread.new do
			# TODO: Extract this shit to a config file
			anidb = Net::AniDBUDP.new(@anidb_server, @anidb_port, @anidb_remoteport)
			anidb.connect(@anidb_username, @anidb_password, @anidb_nat)

			while true
				@log.debug("[I] Waiting for next file to get info")
				src = info_queue.pop
				break unless src
				@log.debug("[I] Searching #{File.basename(src[:file])}")
				file = anidb.search_file(File.basename(src[:file]), src[:size], src[:hash], FILE_FFIELDS)
				if file.nil?
					@log.warn("[I] #{src} can't be found. Skipping.")
					next
				end
				@log.info("[I] #{File.basename(src[:file])} => #{file[:anime][:romaji_name]} (EP: #{file[:anime][:epno]}, FID: #{file[:fid]}, AID: #{file[:file][:aid]})")


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
				process_queue << {:src => src, :file => file}
				@log.debug("[I] Added #{File.basename(src[:file])} to process queue")
			end

			anidb.logout
			process_queue << nil
		end

		process_worker = Thread.new do
			# All that's left is to rename or print
			while true
				@log.debug("[P] Waiting for next file to process")
				file = process_queue.pop
				break unless file
				@log.debug("[P] Processing #{File.basename(file[:src][:file])}")
				renamed_file = @renamer.call(file[:file])


				puts @testmode
				
				if @testmode
					@log.info("[P] Would rename #{File.basename(file[:src][:file])} to #{renamed_file}")
				else
					basepath = File.dirname(file[:src][:file])

					if @animebase and not ["Movie", "OVA"].include?(file[:file][:anime][:type])
						anime_name = [file[:file][:anime][:romaji_name], file[:file][:anime][:english_name]].find {|x| not x.nil?}
						basepath = @animebase + "/" + anime_name
						FileUtils.mkdir_p(basepath)
					end
					
					if @moviebase and ["Movie", "OVA"].include?(file[:file][:anime][:type])
						puts "bang"
						basepath = @moviebase
					end

					FileUtils.mv(file[:src][:file], "#{basepath}/#{renamed_file}")
					@log.info("[P] Renamed #{File.basename(file[:src][:file])} to #{basepath}/#{renamed_file}")
				end
				#pp file
			end
		end

		@log.info("Workers are up and waiting. Let's give them some work.")

		files.each do |file|
			if File.file?(file)
				ed2k_queue << file
				@log.info("[F] Added #{file} to queue")
			end
		end

		ed2k_queue << nil

		[ed2k_worker, info_worker, process_worker].each(&:join)
	end
end