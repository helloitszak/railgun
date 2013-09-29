# encoding: UTF-8
class Biribiri::Helpers
	def self.truncate(s, length = 30, ellipsis = '…')
		if s.length > length
			s.to_s[0..length].gsub(/[^\w]\w+\s*$/, ellipsis)
		else
			s
		end
	end

	def self.middletrunc(s, length=50, ellipsis = '…')
		if s.length > length + 1
			chunksize = length / 2

			startchunk = s[0, chunksize]
			endchunk = s[-chunksize, chunksize]
			startchunk.strip + ellipsis + endchunk.strip
		else
			s
		end
	end
end