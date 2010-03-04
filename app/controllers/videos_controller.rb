class VideosController < ApplicationController
  def index
    @videos = Video.all
  end
  
	def search
		@results = Search.new params
		respond_to do |wants|
			wants.xml
		end
	end

  def show
		unless(@video = Video.find(params[:id]))
    	render :text => "", :status => 401 and return
		end
		respond_to do |wants|
			wants.xml
			wants.html
		end
  end
  
  def new
    @video = Video.new
  end
  
  def create
		debugger
    @video = Video.new(params[:video])
    if @video.save
			debugger
			Video.unespecial! params[:special_to_remove] if @video.special?
      @video.start_jobs!
      flash[:notice] = "Successfully created video."
      redirect_to @video
    else
      render :action => 'new'
    end
  end
  
  def edit
    @video = Video.find(params[:id])
  end
  
  def update
    @video = Video.find(params[:id])
    if @video.update_attributes(params[:video])
			Video.unespecial! params[:special_to_remove] if @video.special? 
      flash[:notice] = "Successfully updated video."
      redirect_to @video
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @video = Video.find(params[:id])
    @video.destroy
    flash[:notice] = "Successfully destroyed video."
    redirect_to videos_url
  end
	
	def can_be_special
		render :text => "" and return if params[:special] == 'null'
		specials = Video.all :special => true
		video = Video.find params[:video_id]
		if specials.size > 5
			unless video and specials.include? video
				render :partial => "special_remove", :locals => {:specials => specials} and return
			end
		end
		render :text => ""
	end
			
	
	def reset 
		@video = Video.find params[:id]
		@video.reset!
		flash[:notice] = "Video reseted, encoding has begun again." 
	rescue Expection => e 
		flash[:error] = e.message
	ensure
		redirect_to @video
	end
end
