class PublisherWorker < Workling::Base
  def config
    CONFIG["publishers"]
  end
  def publish params
    errors = [] and video = Video.find(params[:video_id])
    uploader = YouTubeG::Upload::VideoUpload.new(config['youtube']['username'], config['youtube']['password'], config['youtube']['api_key'])
    uploader.upload File.open("video."), :title => 'test', :description => '', :category => 'People', :keywords => %w[bla]
    
    if errors.empty?
      video.archive!
    else
      video.errors << errors
      video.save! and video.error!
    end
       
  end
    

end
