class ArchiverWorker < Workling::Base
  def archive params
    errors = [] and video = Video.find(params[:video_id])
    
    if errors.empty?
      video.done!
    else
      video.errors << errors
      video.save! and video.error!
    end
       
  end
    

end