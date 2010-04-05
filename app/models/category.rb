class Category
  include MongoMapper::Document
	include Paperclip
	#include Claire::MediaItem
	
	key :name, String, :required => true
  key :description, String
	 
  many :subcategories

	#raw/thumbnails info
  key :image_file_name, String
  key :image_file_size, Integer
  key :image_content_type, String
  key :image_updated_at, DateTime
	key :tags, String
  
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
  
	MEDIA_TYPES = CONFIG['general']['media_types']	
  MEDIA_TYPES.each do |type|
  	# runs a count of items of this type that has this object as parent
		define_method "num_#{type}" do
	     type.classify.constantize.count :"#{self.class.to_s.downcase}_id" => id
		end
		
		# returns all items of this type that has this object as parent
		class_eval <<-METHOD
			def #{type} args={}
				args[:order] ||= "created_at DESC"
				args.merge!({:"#{self.class.to_s.downcase}_id" => _id})
				#{type.classify.constantize}.all prepare_uid_from_args(args)
			end
		METHOD
	end
	
	USERS_CLASS = CONFIG['general']['users_class'].classify.constantize
	instance_eval	"alias :normal_all :all
								 alias :normal_find :find"
	
	def self.prepare_uid_from_args args
		if args[:user]
			user_id = args[:user].id
		elsif args[:user_id]
			user_id = args[:user_id]
		elsif args[:owner_id]
			user_id = args[:owner_id]
		elsif args[:controller]
			user_id = args[:controller].session[:user_id]
		else
			user_id = nil
		end
				
		args.delete_if { |k,v| %w(user user_id owner_id controller).include? k }
		args.merge!({:owner_id => user_id}) if user_id
		args
	end
									
	def self.find id, args={} 				
		self.normal_find id, prepare_uid_from_args(args)
	end
	
	def self.all args={}
		self.normal_all prepare_uid_from_args(args) 		
	end
			
end
