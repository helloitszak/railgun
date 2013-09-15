class CreateTorrents < ActiveRecord::Migration
	def change
		create_table :torrents do |t|
			t.string :hash_string
			t.datetime :name
			t.boolean :copied, default: false
		end
	end
end