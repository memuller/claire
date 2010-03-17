class ConverterWorker < Workling::Base
  
  #shortcut to global format configuration
  def config
    CONFIG["formats"]
  end
  
	#builds a valid recipe mixing provided params with the default ones.
  def recipe args={}
    raise ArgumentError, "Requires input and output files." unless args.include? 'input' and args.include? 'output' and args.include? 'format'
		
    recipe = "ffmpeg -i #{args['input']} -f #{args['format']}"
    
    args['options'] = {} if args['options'].nil?
		args['options'].each do |k,v|
    	recipe += " -#{k} #{v}"
    end

    if args['format'] == "flv"
      recipe += " - | flvtool2 -U stdin #{args['output']}"
    else
      recipe += " -y #{args['output']}"    
    end
    recipe
  end
  
  def convert params	
    errors = []
    video = Video.find params[:video_id]
		puts "* Converter takes the stage, acting on #{video.id}"
    input = video.uploaded_file_path
    config.each do |format|
			next unless video.encode_to.include? format.first
			puts "** ...on format #{format[0]}..."
    	output = "#{RAILS_ROOT}/public/videos/#{video.id}/#{format[0]}.#{format[1]['format']}"
			time = Time.now	
      system recipe(format.last.merge({'input' => input, 'output' => output }))
      
      #checks for encoding errors using a inspector.
      inspector = RVideo::Inspector.new :file => output
      if inspector.unknown_format? or inspector.duration.nil?      
      	msg = "Encoding of #{resolution} wasn't readable."
				errors << msg
				puts "** " + msg
			else
				time = Time.now - time
				video.encode_times.merge!({format.first => time})
				video.save!
				puts "** ..done on #{time} seconds."
     	end      
    end
    
    if errors.empty?
			puts "* Handling to publisher..."
      video.publish!
    else
			puts "Errors found while encoding, aborting."
      video.worker_errors.push! errors
      video.save! and video.error!
    end
    
       
  end
    

end