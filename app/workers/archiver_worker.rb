class ArchiverWorker < Workling::Base
  def config
  	CONFIG["archiver"]
  end
	def archive args 
		@video = Video.find(args[:video_id])		
		#we'll skip everything if there's no raw file
		unless File.exists? @video.uploaded_file_path
			@video.update_attributes! :warnings => "Video raw was not found, skipping archiving."
			@video.done!
		end
		
		errors = [] and params = {}
		config.each do |k,v|
			v = v.sub("RAILS_ROOT", RAILS_ROOT) and params.merge!({k.to_sym => v}) unless v.nil? 			
		end		
		#folder options means file copy.	
		if params[:folder] and not params[:folder].empty?
			params[:folder] += "/" unless params[:folder].last == "/"
			if params[:folder].include? ":video_id"
				params[:folder] = params[:folder].sub ":video_id", @video.id
			else					
				params[:folder] += @video.id.to_s + "/"
			end
			#if there's an username, that means scp commands.
			if params[:username]
				copy_cmd = "scp -i #{params[:identity]} :original :username@:hostname::folder"
				create_dir_cmd = "ssh #{params[:username]}@#{params[:hostname]} mkdir #{params[:folder]}"
			else
				copy_cmd = "cp :original :folder"
				create_dir_cmd = "mkdir #{params[:folder]}"				
			end
			#replaces params inside the copy URL.			
			params.each do |k,v|
				copy_cmd = copy_cmd.sub ":#{k.to_s}", v
			end
			copy_cmd = copy_cmd.sub ":original", "original.#{@video.video_file_name.split('.').last}"			
			#concats and runs the commands
			commands = [
					create_dir_cmd,
					"cd #{RAILS_ROOT}/public/videos/#{@video.id}",
					copy_cmd,
					"rm original.#{@video.video_file_name.split(".").last}"
				]
			ex = system commands.join(" && ")
		
		#destroys the video.
		elsif params[:destroy]
			ex = system "rm #{RAILS_ROOT}/public/videos/#{@video.id}/original.#{@video.video_file_name.split(".").last}"			
		
		#no options provided - does nothing.
		else
			@video.done!
		end
		
		# were there errors?
		unless ex == true
			LOGGER.error "OS reported errors while archiving, see operation logs above."
			errors << "Errors found while archiving the raw file."
		end				 			 
		    
		if errors.empty?
      @video.done!
    else
      @video.worker_errors = @video.worker_errors | errors
      @video.save! and @video.error!
    end
       
  end
    

end