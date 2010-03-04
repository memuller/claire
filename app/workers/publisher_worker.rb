class PublisherWorker < Workling::Base
  def config
    CONFIG["publishers"]
  end
  def publish params
		video = Video.find params[:video_id]
		errors = []
 		# loops on all publishers specified on the config file
		config.each do |item|
			LOGGER.start "Publishing video #{video.id} on #{item.first.classify}"
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
			end
		end
    
    if errors.empty?
      video.archive!
    else
      video.worker_errors = video.worker_errors | errors
      video.save! and video.error!
    end
       
  end
    

end
