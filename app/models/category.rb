class Category
  include MongoMapper::Document
	include Paperclip
  
	key :name, String, :required => true
  key :description, String
  
  many :subcategories

	#raw/thumbnails info
  key :image_file_name, String
  key :image_file_size, Integer
  key :image_content_type, String
  key :image_updated_at, DateTime
  
  has_attached_file :image, :styles => { :thumb => "215x120"}, 
                    :path => "#{RAILS_ROOT}/public/categories/:id/:style.jpg"

end
