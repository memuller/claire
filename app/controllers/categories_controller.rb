class CategoriesController < ApplicationController
  before_filter :authenticate, :except => :get_subcategories_menu
  def index
    @categories = Category.all    
  end
  
  def videos
		raise "(404) Category not found" unless @category = Category.find(params[:id])
		respond_to do |wants|
			wants.html
			wants.xml do
				set_pagination
				@results = @category.videos
				@item_type = :videos
				render 'videos/search', :format => 'xml'
			end						
		end
	end
	
	def streams
		raise "(404) Category not found" unless @category = Category.find(params[:id])
		respond_to do |wants|
			wants.html
			wants.xml do
				set_pagination
				@results = @category.streams
				@item_type = :streams
				render 'videos/search', :format => 'xml'
			end						
		end
	end
	
  def show
    raise "(404) Category not found" unless @category = Category.find(params[:id])
		respond_to do |wants|
			wants.html
			wants.xml do
				set_pagination
				@results = @category.videos | @category.streams
				render 'videos/search', :format => 'xml'
			end						
		end
	#rescue Exception => e
		#render :text => e.message, :status => get_status_code(e)
  end
  
  def new
    @category = Category.new
  end
  
  def create
    @category = Category.new(params[:category])
    if @category.save
      flash[:notice] = "Successfully created category."
      redirect_to @category
    else
      render :action => 'new'
    end
  end
  
  def edit
    @category = Category.find(params[:id])
  end
  
  def update
    @category = Category.find(params[:id])
    if @category.update_attributes(params[:category])
      flash[:notice] = "Successfully updated category."
      redirect_to @category
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @category = Category.find(params[:id])
    @category.destroy
    flash[:notice] = "Successfully destroyed category."
    redirect_to categories_url
  end
  
  def get_subcategories_menu
    category = Category.find params[:category_id]
    render :partial => "videos/subcategory", :locals => {:subcategories => category.subcategories}
  end
  
end
