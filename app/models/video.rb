class Video
  include MongoMapper::Document
  include StateFu
  include Paperclip

  #general info
  key :title, String
  key :subtitle, String
  key :description, String, :default => ""
  key :tags, Array, :default => []
  key :special, Boolean, :default => false

  #relationships
  belongs_to :category
  key :category_id, ObjectId
  key :subcategory_id, ObjectId

	key :publish_to, Array, :default => []
	key :archive_to, Boolean, :default => []
	key :encode_to, Array, :default => []
  key :formats, Array
	#metadata
  key :duration, Integer

  #statistics
  key :num_ratings, Integer, :default => 0
  key :value_ratings, Integer, :default => 0
  key :rating, Float, :default => 0
  key :num_views, Integer, :default => 0
  timestamps!

	#error and status handling
	key :state_fu_field, String
	key :worker_errors, Array, :default => []
	key :resets, Integer, :default => 0
	key :okay, Boolean, :default => false

	#avoids querying other documents to get those
	key :category_name, String
	key :subcategory_name, String
	key :texts, Array, :default => []

  #raw/thumbnails info
  key :video_file_name, String
  key :video_file_size, Integer
  key :video_content_type, String
  key :video_updated_at, DateTime

  has_attached_file :video, :styles => { :thumb_square => "50x50", :thumb_medium => "215x120", :thumb_large => "500x281" },
                    :processors => [:video_thumbnail],
                    :path => "#{RAILS_ROOT}/public/videos/:id/:style.:video_extensions",
                    :url =>  "videos/:id/:style.:video_extensions"

  machine :default do
		#starting up, video's not here yet
		state :initialized do
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
		 state :error do
		 	on_entry { self.update_attributes! :okay => false }
		 end
		 state :done do
		 	on_entry :okay!
		 end
		 #...and their transitions
		 event :error, :from => :ALL, :to => :error
		 event :done, :from => :ALL, :to => :done
		 event :restart, :from => :ALL, :to => :initialized

		 #save states to the database after each transition
		 states do
		   accepted { save! }
		 end
	end

  #rates an video
	def rate! num
    @num_ratings += 1
    @value_ratings += num
    @rating = (@value_ratings.to_f / @num_ratings.to_f).round(1)
    self.save!
  end

  #retries a conversion
  def start_jobs!
    receive_raw!
    convert!
  end

	#resets video state and retries
	def reset!
		# you can't reset it the raw file is already archived (for now)
		raise "Video couldn't be reset since it's raw file is already archived. If there's still need to process something on this video, you should provide a new raw file." unless File.exists? uploaded_file_path
		# you can't reset it more than 3 times
		raise "Video reached maximum number of resets (3). Please destroy it, and upload a new one." if resets > 3
		self.update_attributes! :resets => @resets + 1, :worker_errors => []
		restart!; start_jobs!
	end

	#sets a video as okay
	def okay!
		self.update_attributes! :okay => true
	end

  #returns raw file path
  def uploaded_file_path
    "#{RAILS_ROOT}/public/videos/#{id}/original.#{video_file_name.split(".").last}"
  end

  #checks if raw exists
  def raw_file_okay?
    File.exists? uploaded_file_path
  end

	#removes a video from the front page
 	def self.unespecial! id
		video = Video.find id rescue return false
		if video
			video.special = false
			video.save!
		end
	end

  #overwrites tags to support reverse indexing on the tag collection
  def update_tags
    tags_that_are_okay = []
    #searchs all tags that have this item indexed
    #and remove this item from here, unless the tag
    #is on this item tags field
    Tag.all(:conditions => {:items => id}).each do |t|
      if tags.include? t.name
        tags_that_are_okay << t.name
      else
        t.items = t.items.reject{ |item| item == id }
        t.save!
      end
    end

    tags.each do |t|
      Tag.set_tag t, id unless tags_that_are_okay.include? t
    end
  end

	# a lots of hooks to be run while saving items.
	before_save lambda{ |video|
		  #converts the tags sent via form (strings) to an array
			if video.tags.size == 1 and video.tags.first.is_a? String 
				video.tags = video.tags.first.split(" ")
			end
			#caches category name
			video.category_name = video.category.name if video.category
			if video.subcategory_id and video.category
			  subcategory = video.category.subcategories.select{|cat| cat.id == video.subcategory_id}.first
			  video.subcategory_name = subcategory.name unless subcategory.nil?
	    end
			#updates the indexable texts field with desc, title and subtitle
			title = video.title.split(" ")
			description = video.description.split(" ")
			video.texts = (title | description | video.tags).uniq!
			#maps string values (again, comming from forms) to symbols.
			video.publish_to.map!(&:to_sym)
		}
  after_save :update_tags

	#when destroying an video, also destroy its files
	before_destroy lambda{ |video|
			system("rm -fr #{RAILS_ROOT}/public/videos/#{video.id}")
		}

  #returns an list of avaliable encode profiles
  def avaliable_formats
    arr = []
    CONFIG.each do |item|
      arr << item[0]
    end
    arr
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
	def encoded_video_url(format="#{formats.first}")
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

	#shortens description
	def short_description
		return "" if description.nil? or description.empty?
		if description.length > CONFIG['general']['videos']['short_description_length']
			str = ""
			description.split(" ").each do |word|
				if (str + word).length > CONFIG['videos']['short_description_length'] -3
					str += "..."
					return str
				else
					str += word
				end
			end
		else
			return description
		end
	end
  #returns tags as strings
	def tags_as_string
		tags.join(", ")
	end

	#a simple way to get related videos
	def related
		Video.all :category_id => category_id, :order => "num_views DESC, updated_at DESC", :limit => 5
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

