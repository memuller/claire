class SubcategoriesController < ApplicationController
  def index
    @subcategories = Subcategory.all
  end
  
  def show
    @subcategory = Subcategory.find(params[:id])
  end
  
  def new
    @subcategory = Subcategory.new
  end
  
  def create
		@category = Category.find params[:category][:id]
    @subcategory = Subcategory.new(params[:subcategory])
    @category.subcategories << @subcategory 
		if @category.save
      flash[:notice] = "Successfully created subcategory."
      redirect_to @subcategory
    else
      render :action => 'new'
    end
  end
  
  def edit
    @subcategory = Subcategory.find(params[:id])
  end
  
  def update
    @subcategory = Subcategory.find(params[:id])
    if @subcategory.update_attributes(params[:subcategory])
      flash[:notice] = "Successfully updated subcategory."
      redirect_to @subcategory
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @subcategory = Subcategory.find(params[:id])
    @subcategory.destroy
    flash[:notice] = "Successfully destroyed subcategory."
    redirect_to subcategories_url
  end
end
