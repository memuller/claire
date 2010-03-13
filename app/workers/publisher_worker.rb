class PublisherWorker < Workling::Base
  def config
    CONFIG["publishers"]
  end
  def publish params
		video = Video.find params[:video_id]
		errors = []
		puts "* Publisher takes the stage, acting on #{video.id}..."
 		# loops on all publishers specified on the config file
		config.each do |item|
			next unless video.publish_to.include? item.first
			puts "** ...#{item.first}..."
			# gets a publisher from the Publishers module with the specified name
			klass = Publishers.const_get(item.first.classify)
			
			# builds an options array to initialize the publisher.
			# just converts the string keys from the yaml to symbols.
			options = {}
			item.last.each do |k,v|
				options.merge!({k.to_sym => v})
			end
			options.merge!({:video => video})
			
			# instantiate the publisher with those options
			publisher = klass.new(options)
			
			# publishes; if it doesn't return true, get its errors.
			unless (result = publisher.publish!) == true
				errors << result
				puts "** ERROR: #{result}"
			else
				puts "** ...done!"
			end
		end
    
    if errors.empty?
			puts video.default.name
      video.archive!
			puts "* Handling to archiver..."
    else
			puts "* Errors were found while publishing, aborting."
      video.worker_errors = video.worker_errors | errors
      video.save! and video.error!
    end
       
  end
    

end
