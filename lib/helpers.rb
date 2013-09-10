# encoding: UTF-8
class Helpers
	def self.truncate(s, length = 30, ellipsis = '…')
		if s.length > length
			s.to_s[0..length].gsub(/[^\w]\w+\s*$/, ellipsis)
		else
			s
		end
	end
end