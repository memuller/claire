class StreamsController < ApplicationController
  
	def search
		set_pagination 				
		set_search_terms
		params.merge!({:what => :streams}) and @item_type = :streams
		get_results				
		respond_to do |wants|
			wants.xml do
				render 'videos/search',  :format => 'xml'
			end
		end
		
	#rescue Exception => e
		#render :text => e.message, :status => get_status_code(e)
	end

	def index
		@item_type = :streams		
    @streams = Stream.all
  end
  
  def show
    @stream = Stream.find(params[:id])
  end
  
  def new
    @stream = Stream.new
  end
  
  def create
    @stream = Stream.new(params[:stream])
    if @stream.save
      flash[:notice] = "Successfully created stream."
      redirect_to @stream
    else
      render :action => 'new'
    end
  end
  
  def edit
    @stream = Stream.find(params[:id])
  end
  
  def update
    @stream = Stream.find(params[:id])
    if @stream.update_attributes(params[:stream])
      flash[:notice] = "Successfully updated stream."
      redirect_to @stream
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @stream = Stream.find(params[:id])
    @stream.destroy
    flash[:notice] = "Successfully destroyed stream."
    redirect_to streams_url
  end
end
