class Backlog < ActiveRecord::Base
	validates :path, uniqueness: true, presence: true
end