class ConverterWorker < Workling::Base
  
  #shortcut to global format configuration
  def config
    CONFIG["formats"]
  end
  
	#builds a valid recipe mixing provided params with the default ones.
  def recipe args={}
    raise ArgumentError, "Requires input and output files." unless args.include? 'input' and args.include? 'output' and args.include? 'format'
    params = {
	  	'audio_bitrate' => 64*1000,
			'audio_frequency' => 22050,
			'video_bitrate' => 200*1000,
			'fps' => 29.87,
			'resolution' => '480x270'	
		}
		params.merge! args
    
    #audio params...
    recipe = "ffmpeg -i #{params['input']} -f #{params['format']} -ar #{params['audio_frequency']} -ab #{params['audio_bitrate']} "
    #video params...
    recipe += "-r #{params['fps']} -s #{params['resolution']} -vb #{params['video_bitrate']}"
    #if it's an flv, use flvtool for tagging
    if params['format'] == "flv"
      recipe += " - | flvtool2 -U stdin #{params['output']}"
    else
      recipe += "-y #{params['output']}"    
    end
    recipe
  end
  
  def convert params
	
    errors = []
    video = Video.find params[:video_id]
    input = video.uploaded_file_path
    config.each do |format|
			puts video.encode_to.include? format[0].to_sym
			next unless video.encode_to.include? format[0].to_sym
    	output = "#{RAILS_ROOT}/public/videos/#{video.id}/#{format[0]}.#{format[1]['format']}"
      system recipe(format[1].merge({'input' => input, 'output' => output }))
      
      #checks for encoding errors using a inspector.
      inspector = RVideo::Inspector.new :file => output
      if inspector.unknown_format? or inspector.duration.nil?      
      	errors << "Encoding of #{resolution} reported no erros, but resulting encoded file wasn't readable." 
     	end      
    end
    
    if errors.empty?
      video.publish!
    else
      video.worker_errors.push! errors
      video.save! and video.error!
    end
    
       
  end
    

end