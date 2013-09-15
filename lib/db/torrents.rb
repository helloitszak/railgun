class Torrents < ActiveRecord::Base
	validates :hash, uniqueness: true, presence: true
end