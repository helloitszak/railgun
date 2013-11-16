require "biribiri/processor"
class Biribiri::XbmcRenamer < Biribiri::Processor::Plugin
	attr_accessor :animebase, :moviebase, :backlog_set
	SPECIAL_MAP = {
		"S" => "S",
		"C" => "S1",
		"T" => "S2",
		"P" => "S3",
		"O" => "S4"
	}

	def initialize(animebase, moviebase)
		@animebase = animebase
		@moviebase = moviebase
	end


	def standalone?(anime)
		["Movie", "OVA"].include?(file[:file][:anime][:type]) and not file[:file][:anime][:episodes] > 1
	end

	def process(processor, file)
		renamed_file = self.rename(file[:file])

		if processor.testmode
			Logger.log.info("[P] Would rename #{File.basename(file[:src][:file])} to #{renamed_file}")
		else
			basepath = File.dirname(file[:src][:file])

			if @animebase and not standalone?(file)
				anime_name = [file[:file][:anime][:romaji_name], file[:file][:anime][:english_name]].find {|x| not x.nil?}
				anime_name.gsub!(/[\\\":\/*|<>?]/, " ")
				anime_name.gsub!(/\s+/, " ")
				anime_name.gsub!(/^\s|\s$/, "")
				anime_name.gsub!(/`/, "'")
				anime_name.gsub!(/\.$/, "")
				basepath = @animebase + "/" + anime_name
				FileUtils.mkdir_p(basepath)
			end
			
			if @moviebase and standalone?(file)
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

	def rename(file)
		episode_title = [file[:anime][:ep_english_name], file[:anime][:ep_romaji_name]].find {|x| not x.nil?}

		# Show Title
		show_title = [file[:anime][:romaji_name], file[:anime][:english_name]].find {|x| not x.nil?}
		show_title.gsub!(/[\\\":\/*|<>?]/, " ")
		show_title.gsub!(/\s+/, " ")
		show_title.gsub!(/^\s|\s$/, "")
		show_title.gsub!(/`/, "'")
		show_title = Helpers.truncate(show_title, 48)

		# Episode Title
		episode_title = [file[:anime][:ep_english_name], file[:anime][:ep_romaji_name]].find {|x| not x.nil?}
		episode_title.gsub!(/[\\\":\/*|<>?]/, " ")
		episode_title.gsub!(/\s+/, " ")
		episode_title.gsub!(/^\s|\s$/, "")
		episode_title.gsub!(/`/, "'")
		episode_title = Helpers.truncate(episode_title, 64)

		# Episode Number
		regular = ""
		special = "S"
		seperator = " - "

		specialtag = file[:anime][:epno].gsub(/[1234567890]/, "")
		padlength = (specialtag.empty? ? file[:anime][:highest_episode_number].to_s.length : 2)

		# The to_i.to_s is to strip leading 0s from the episode number
		episodeno = file[:anime][:epno].gsub(/[SCTPO]/, "").to_i.to_s.rjust(padlength, "0")
		version = (file[:file][:version] == 1 ? "" : "v#{file[:file][:version]}")

		specialno = (SPECIAL_MAP.include?(specialtag) ? SPECIAL_MAP[specialtag] : "")
		fullepno = [" - ", specialno, episodeno, version, " - "] * ""

		# File info
		group = "[#{[file[:anime][:group_short_name], file[:anime][:group_name]].find {|x| not x.nil?}}]"
		src = "[#{file[:file][:source].gsub("Blu-ray", "BluRay")}]"
		cen = file[:censoredstatus] ? "[Cen]" : ""
		res = "[#{file[:file][:video_resolution]}]"
		vcodec = "[#{file[:file][:video_codec].gsub("H264/AVC", "h264")}]"
		acodec = "[#{file[:file][:audio_codec_list]}]"
		crc = "(#{file[:file][:crc32].upcase})"

		fileinfo = [" ", group, src, cen, res, vcodec, crc] * ""

		# File Name
		if standalone?(file)
			# Process Movie
			[show_title, fileinfo, ".", file[:file][:file_type]] * ""
		else
			# Process episodic
			[show_title, fullepno, episode_title, fileinfo, ".", file[:file][:file_type]] * ""
		end

		fullfile
	end
end
