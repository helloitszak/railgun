class Torrents < ActiveRecord::Base
	validates :hash_string, uniqueness: true, presence: true
end
