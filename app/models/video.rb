class Video
  include MongoMapper::Document
  include StateFu
  include Paperclip
  
  def logger
    Rails.logger
  end
                     
  #state machine controller  
  key :state_fu_field, String
  #general info
  key :name, String
  key :subtitle, String
  key :description, String
  key :tags, String
  key :category_id, ObjectId
  key :subcategory_id, ObjectId
  key :desired_formats, Array
  #metadata
  key :duration, Integer
  #statistics
  key :num_ratings, Integer
  key :value_ratings, Integer
  key :rating, Integer
  key :num_views, Integer
  
  #raw/thumbnails info
  key :video_file_name, String
  key :video_file_size, Integer
  key :video_content_type, String
  key :video_updated_at, DateTime
  
  has_attached_file :video, :styles => { :thumb_medium => "215x120", :thumb_large => "500x281" }, 
                    :processors => [:video_thumbnail],
                    :path => "#{RAILS_ROOT}/public/videos/:id/:style.:video_extensions"
  #relationships
  belongs_to :category
  belongs_to :subcategory

  machine :default do 
    #starting up, video's not here yet
    state :initialized do 
      requires :name
      event :check_upload, :to => :raw_received
    end
    
    #raw's here
    state :raw_received do
      requires :raw_file_okay?
      event :convert, :to => :converting
    end
    
    #them convert it
    state :converting do
      requires :raw_format_okay?
      on_entry :work_on_conversions
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
  
    #save states to the database after each transition
    states do
      accepted { 
        puts "changed state"
        #status = current_state
        save! 
      }
    end  
  end                              
  
  #writes an uploaded raw to it's destination
  def write_uploaded_file(upload)
    File.open raw_file_path, 'wb' do |f|
      f.write upload[:datafile].read
    end
  end
  
  #returns raw file path
  def uploaded_file_path
    "#{RAILS_ROOT}/public/videos/#{id}/original.#{video_file_name.split(".").last}"
  end
  
  #checks if raw exists
  def raw_file_okay?
    File.exists? uploaded_file_path
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
  
  #== WORKERS
  
  
  
  def work_on_publishing(target)
    raise NotImplementedError unless [:youtube, :localhost].include? target
  end
  
  
end
