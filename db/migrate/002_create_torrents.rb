class CreateTorrents < ActiveRecord::Migration
	def change
		create_table :torrents do |t|
			t.string :hash
			t.datetime :name
			t.boolean :copied, default: false
		end
	end
end