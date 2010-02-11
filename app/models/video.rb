class Video
  include MongoMapper::Document
  include StateFu
  
  #mongo keys  
  key :status, Symbol
  key :name, String
  key :description, String
  key :tags, String
  key :category_id, ObjectId
  key :subcategory_id, ObjectId
  key :desired_formats, Array
  key :num_ratings, Integer
  key :value_ratings, Integer
  key :rating, Integer
  key :num_views, Integer  
  
  #relationships
  belongs_to :category
  belongs_to :subcategory
  
  machine :status do 
    #starting up, video's not here yet
    state :initialized do 
      requires :name
      event :next!, :to => :raw_received
    end
    #raw's here
    state :raw_received do
      requires :raw_file_okay?
      event :next!, :to => :thumbnailing
    end
    #let's thumbnail it
    state :thumbnailing do
      requires :raw_format_okay?
      on_entry :work_on_thumbnails
      event :next!, :to => :converting
    end
    #them convert it
    state :converting do
      on_entry :work_on_conversions
      event :next!, :to => :publishing
    end
    #publish the converted files
    state :publishing do
      on_entry :work_on_publishing
      event :next!, :to => :archiving
    end
    #archive the raw
    state :archiving do
      on_entry :work_on_archiving
    end
    
    #blank, signaling states
    state :error
    state :done 
    #...and their transitions
    event :error!, :from => :ALL, :to => :error
    event :nothing_to_do!, :from => :ALL, :to => :done 
       
  end
  
  #save states to the database after each transition
  states do
    accepted { save! }
    
  #returns the path for this video's raw file
  def raw_file_path                          
    "#{RAILS_ROOT}/videos/raw/#{self._id}"    
  end
  
  #writes an uploaded raw to it's destination
  def write_uploaded_file(upload)
    File.open raw_file_path, 'wb' do |f|
      f.write upload[:datafile].read
    end
  end
  
  #checks if raw exists
  def raw_file_okay?
    File.exists uploaded_file_path
  end
  
  #checks if raw is a valid, convertible video
  def format_okay?
    
  end
  
  #== WORKERS
  def work_on_thumbnails
    
  end
  
  def make_thumbnails
    
  end
  
  
  
  def publish(target)
    raise NotImplementedError unless [:youtube, :localhost].include? target
  end
  
  
end
