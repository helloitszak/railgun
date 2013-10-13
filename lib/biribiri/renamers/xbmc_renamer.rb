require "biribiri/processor"
class Biribiri::XbmcRenamer < Biribiri::Processor::Renamer
	SPECIAL_MAP = {
		"S" => "S",
		"C" => "S1",
		"T" => "S2",
		"P" => "S3",
		"O" => "S4"
	}
	def self.rename(file)
		episode_title = [file[:anime][:ep_english_name], file[:anime][:ep_romaji_name]].find {|x| not x.nil?}

		# Show Title
		show_title = [file[:anime][:romaji_name], file[:anime][:english_name]].find {|x| not x.nil?}
		show_title.gsub!(/[\\\":\/*|<>?]/, " ")
		show_title.gsub!(/\s+/, " ")
		show_title.gsub!(/^\s|\s$/, "")
		show_title.gsub!(/`/, "'")
		show_title = Helpers.truncate(show_title, 64)

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
		fullfile = case file[:anime][:type]
		when "Movie", "OVA"
			# Process Movie
			[show_title, fileinfo, ".", file[:file][:file_type]] * ""
		else
			# Process episodic
			[show_title, fullepno, episode_title, fileinfo, ".", file[:file][:file_type]] * ""
		end

		fullfile
	end
end
