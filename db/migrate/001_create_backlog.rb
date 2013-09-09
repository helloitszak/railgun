class CreateBacklog < ActiveRecord::Migration
	def change
		create_table :backlogs do |t|
			t.string :path
			t.datetime :expire
			t.datetime :added
			t.integer :runs, default: 0
		end
	end
end