# encoding: UTF-8
# TODO: If we are using active_record, why not use active_support.
class Hash
	def deep_transform_keys(&block)
		result = {}
		each do |key, value|
			result[yield(key)] = value.is_a?(Hash) ? value.deep_transform_keys(&block) : value
		end
		result
	end

	def deep_symbolize_keys
		deep_transform_keys{ |key| key.to_sym rescue key }
	end

	def deep_merge!(other_hash)
		other_hash.each_pair do |k,v|
			tv = self[k]
			self[k] = tv.is_a?(Hash) && v.is_a?(Hash) ? tv.deep_merge(v) : v
		end
		self
	end

	def deep_merge(other_hash)
		dup.deep_merge!(other_hash)
	end
end


def truncate(s, length = 30, ellipsis = '…')
	if s.length > length
		s.to_s[0..length].gsub(/[^\w]\w+\s*$/, ellipsis)
	else
		s
	end
end