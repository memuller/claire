class Video
  include MongoMapper::Document
  include StateFu
  include Paperclip
                     
  #state machine controller  
  key :state_fu_field, String
  #general info
  key :name, String
  key :subtitle, String
  key :description, String
  key :category_id, ObjectId
  key :subcategory_id, ObjectId
  key :formats, Array
  #metadata
  key :duration, Integer
  #statistics
  key :num_ratings, Integer, :default => 0
  key :value_ratings, Integer, :default => 0
  key :rating, Float, :default => 0
  key :num_views, Integer, :default => 0
  timestamps!
  
  #raw/thumbnails info
  key :video_file_name, String
  key :video_file_size, Integer
  key :video_content_type, String
  key :video_updated_at, DateTime
  
  has_attached_file :video, :styles => { :thumb_medium => "215x120", :thumb_large => "500x281" }, 
                    :processors => [:video_thumbnail],
                    :path => "#{RAILS_ROOT}/public/videos/:id/:style.:video_extensions",
                    :url =>  "videos/:id/:style.:video_extensions"
  #relationships
  belongs_to :category
  belongs_to :subcategory

  machine :default do 
    #starting up, video's not here yet
    state :initialized do 
      requires :name
      event :receive_raw, :to => :raw_received
    end
    
    #raw's here
    state :raw_received do
      requires :raw_file_okay?      
      event :convert, :to => :converting
    end
    
    #them convert it
    state :converting do
      requires :raw_format_okay?
      on_entry :work_on_converting
      event :publish, :to => :publishing
    end
    #publish the converted files
    state :publishing do
      on_entry :work_on_publishing
      event :archive, :to => :archiving
    end
    #archive the raw
    state :archiving do
      on_entry :work_on_archiving
    end
    
    #blank, signaling states
    state :error
    state :done 
    #...and their transitions
    event :error, :from => :ALL, :to => :error
    event :done, :from => :ALL, :to => :done
    event :reset, :from => :ALL, :to => :initialized 
  
    #save states to the database after each transition
    states do
      accepted {
        save! 
        }
    end  
  end
  
  #the save method will, by default, ignite the conversion routines if the video
  #has just been created.
  #alias :old_save :save
  #def save
  #  self.old_save
  #  if self.initialized?
  #    receive_raw! 
  #  end
  #end
                                  
  
  #returns raw file path
  def uploaded_file_path
    "#{RAILS_ROOT}/public/videos/#{id}/original.#{video_file_name.split(".").last}"
  end                 
  
  #checks if raw exists
  def raw_file_okay?
    File.exists? uploaded_file_path
  end
  
	def update_category_name
  	category_name = category.name and save! unless category.nil?
	end
	
	def update_subcategory_name
		subcategory_name = category.subcategories
	end
  
	#returns an hash with all encoded videos urls
  def encoded_videos_url
    hash = {}
    formats.each do |fmt|
      hash.merge!({"#{fmt}" => encoded_video_url(fmt)})
    end
    hash
  end
  
  #returns urls for a specific encoded video
	def encoded_video_url format
    "/videos/#{id}/#{format}.#{CONFIG['formats'][format]['format']}" 
  end
  
  #returns url for video thumbnails
	def thumbnail_url(format= :thumb_medium)
    "/videos/#{id}/thumb_#{format.to_s}.jpg"
  end                                  
  
  
  #checks if raw is a valid, convertible video
  def raw_format_okay?
     begin
       inspector = RVideo::Inspector.new :file => uploaded_file_path
       duration = inspector.duration
       save! and return true
     rescue ArgumenError => e
     	 return false
     end     
  end
  
	#a simple way to get related videos
	def related
		Video.all :category_id => category_id, :order => "num_views DESC, updated_at DESC", :limit => 5
	end
  #into_xml
  def into_xml(type= :long)
    hash = {
      :title => name,
      :category => category_name,
      :subcategory => subcategory_name,
      :rating => rating
    }
    if type == :long
      hash.merge!({
        :description => description
      })
    end
    hash    
  end
  
  #== WORKERS    
  def work_on_publishing
    PublisherWorker.asynch_publish :video_id => _id
  end
  def work_on_converting
    ConverterWorker.asynch_convert :video_id => id
  end
  def work_on_archiving
    ArchiverWorker.asynch_archive :video_id => id
  end  
end
