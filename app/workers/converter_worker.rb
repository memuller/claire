class ConverterWorker < Workling::Base
  
  #shortcut to global format configuration
  def config
    CONFIG["formats"]
  end
  
  #builds a valid recipe mixing provided params with the default ones.
  def recipe args={}
    raise ArgumentError, "Requires input and output files." unless args.include? :input and args.include? :output
    args.each_with_keys do |k,v|
      eval "#{k} = #{v}"
    end
    #default parameters
    audio_bitrate ||= 64
    audio_frequency ||= 22050
    video_bitrate ||= 200*1000
    fps ||= 29.97
    format ||= "flv"
    resolution ||= "480x270"
    
    #audio params...
    recipe = "ffmepg -i #{input} -f #{format} -ar #{audio_frequency} -ab #{audio_bitrate}"
    #video params...
    recipe += "-r #{fps} -s #{resolution} -vb #{video_bitrate}"
    #if it's an flv, use flvtool for tagging
    if format == "flv"
      recipe += " - | flvtool2 -U stdin #{output}"
    else
      recipe += "-y #{output}"    
    end
    recipe
  end
  
  def convert params
    errors = []
    video = Video.find params[:video_id]
    input = video.uploaded_file_path
    transcoder = RVideo::Transcoder.new
    config.formats.each do |format|
      output = "#{RAILS_ROOT}/public/videos/#{video.id}/#{format.resolution}.#{format.format}"
      begin
        transcoder.execute( recipe(
                              format.merge({:input => input, 
                                            :output => output }) 
                            )
        )
      rescue 
        logger.info "Error'ed, but it's quite possibly just LAME being lame =)"
      end
      
      #checks for encoding errors using a inspector.
      begin
        inspector = RVideo::Inpector.new :file => output
        reading_error = true if inspector.unknown_format? or inspector.duration.nil?
      rescue 
        reading_error = true
      end
      
      if defined? reading_error and reading_error == true
        errors << "Encoding of #{resolution} reported no erros, but resulting encoded file wasn't readable." 
      end
      
    end
    
    if errors.empty?
      video.publish!
    else
      video.errors << errors
      video.save! and video.error!
    end
    
       
  end
    

end