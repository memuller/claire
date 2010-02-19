class VideosController < ApplicationController
  def index
    @videos = Video.all
  end
  
  def show
    @video = Video.find(params[:id])
  end
  
  def new
    @video = Video.new
  end
  
  def create
    @video = Video.new(params[:video]) 
    if @video.save
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
end
