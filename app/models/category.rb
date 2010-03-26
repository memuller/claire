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
  
  has_attached_file :image, :styles => { :thumb_square => "50x50"}, 
                    :path => "#{RAILS_ROOT}/public/categories/:id/:style.jpg"

	#returns thumbnail url
	def thumbnail_url
		"/public/categories/#{id}/thumb_square.jpg"		
	end
	
	#returns original image url
	def image_url
		"/public/categories/#{id}/original.jpg"		
	end                                       									
                  
  #returns a list of its subcategories names
	def subcategories_names
    arr = []
    subcategories.each do |i|
      arr << i.name
    end
		arr.join(", ")
  end
  
	def num_videos
		Video.count :category_id => id
	end

	# fetches all of this category's videos
	def videos args={}
		args[:order] ||= "created_at DESC"
		args.merge!({:category_id => id})
		Video.all args 
	end
end
