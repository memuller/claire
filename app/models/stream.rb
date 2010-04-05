class Stream
	include MongoMapper::Document
	
	key :title, String, :required => true
	key :width, Integer
	key :heigth, Integer
	key :url, String, :required => true
	key :format, String
	
	key :has_audio, String, :default => :yes
	key :has_video, String, :default => :yes
	
	key :okay, Boolean, :default => true	
	
	belongs_to :category
	key :category_id, ObjectId
	key :category_name, String, :default => ""
	
	before_save lambda { |item|
			puts "a"
			item.category_name = item.category.name if item.category
		}
	
end
