class ConverterWorker < Workling::Base
  def config
    CONFIG["formats"]
  end
  
  def recipe args={}
    raise ArgumentError, "Requires input and output files." unless args.include? :input and args.include? :output
    args.each_with_keys do |k,v|
      eval "#{k} = #{v}"
    end
    audio_bitrate ||= 64
    audio_frequency ||= 22050
    video_bitrate ||= 200*1000
    fps ||= 29.97
    format ||= "flv"
    resolution ||= "480x270"
    
    recipe = "ffmepg -i #{input} -f #{format} -ar #{audio_frequency} -ab #{audio_bitrate}"
    recipe += "-r #{fps} -s #{resolution} -vb #{video_bitrate}"
    if format == "flv"
      recipe += " - | flvtool2 -U stdin #{output}"
    else
      recipe += ""    
    end
  
  def convert params
    errors = []
    video = Video.find params[:video_id]
    transcoder = RVideo::Transcoder.new
    recipe = "ffmpeg -i $input_file$ -ar 22050 -ab 128 -r 29.97 -f flv -b 2000000 -s $resolution$ - | flvtool2 -U stdin $output_file$"
    %w(960x540 480x270).each do |resolution|
      output = "#{RAILS_ROOT}/public/videos/#{video.id}/#{resolution}.flv"
      begin
        transcoder.execute(recipe, {
          :input_file => video.uploaded_file_path,
          :output_file => output, 
          :resolution => resolution
        }) 
      rescue 
        logger.info "Error'ed, but it's quite possibly just LAME being lame =)"
      end
      
      begin
        inspector = RVideo::Inpector.new :file => output
        reading_error = true if inspector.unknown_format? or inspector.duration.nil?
      rescue 
        reading_error
      end
      errors << "Encoding of #{resolution} reported no erros, but resulting encoded file wasn't readable." if defined? reading_error      
    end #ends resolution loop
    
    if errors.empty?
      video.publish!
    else
      video.errors << errors
      video.save! and video.error!
    end
       
  end
    

end