class VideosController < ApplicationController
  before_filter :authenticate, :except => :can_be_special
	def index
		@videos = Video.all
  end
  
	def search
		set_pagination 				
		set_search_terms
		get_results				
		respond_to do |wants|
			wants.xml
		end
		
	#rescue Exception => e
		#render :text => e.message, :status => get_status_code(e)
	end

  def show
		unless(@video = Video.find(params[:id]))
    	render :text => "", :status => 401 and return
		end
		respond_to do |wants|
			wants.xml do
				render :partial => 'show'
			end
			wants.html
		end
  end
  
  def new
    @video = Video.new
  end
  
  def create
    @video = Video.new(params[:video])
    if @video.save
			Video.unespecial! params[:video][:special_to_remove] if @video.special?
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
			Video.unespecial! params[:video][:special_to_remove] if @video.special? 
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
		if specials.size >= 5
			unless video and specials.include? video
				render :partial => "special_remove", :locals => {:specials => specials} and return
			end
		end
		render :text => ""
	end
	
	def rate
		video = Video.find params[:id]
		params[:rating] = params[:value] if params[:value]
		params[:rating] = params[:rating].to_i
		video.rate! params[:rating]
	rescue
		render_text 'ERROR', :status => 400
	end
	
	def view
		video = Video.find params[:id]
		video.update_attributes! :num_views => video.num_views + 1
		render_text "OK", :status => 200
	rescue
		render_text "ERROR", :status => 400
	end
	
	def top_rated
    params[:order] = "rating DESC"
    set_pagination and set_search_terms and get_results
    respond_to do |wants|
    	wants.xml{ render "search" }
    end
	end
	
	def most_viewed
    params[:order] = "views DESC"
    set_pagination and set_search_terms and get_results
    respond_to do |wants|
    	wants.xml{ render "search" }
    end
	end
	
	def specials
		params[:special] = true
    set_pagination and set_search_terms and get_results
    respond_to do |wants|
    	wants.xml{ render "search" }
    end
	end
	
			
	
	def reset 
		@video = Video.find params[:id]
		@video.reset!
		flash[:notice] = "Video reseted, encoding has begun again."
		status = 200 
	rescue Expection => e 
		flash[:error] = e.message and status = 400
	ensure
		redirect_to :action => :show, :status => status, :params => {:id => @video.id}
	end
end
