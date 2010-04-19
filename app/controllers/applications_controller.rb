class ApplicationsController < ApplicationController
  before_filter :authenticate
  def redirector
		app = Application.find_by_username params[:appname]
		params.merge!({:owner_id => app.id})
		action = params[:kaction] and controller = params[:klass]
		params.delete_if{ |k,v| %w(controller action appname klass kaction).include? k }		
		redirect_to :controller => controller, :action => action, :params => params
	end
	
	def logout
		session.clear
		flash[:error] = "You have logged out."
		redirect_to root_url		
	end
	
	def login
		if request.method == :post			
			if session[:user_id]
				flash[:notice] = "You have logged in." and redirect_to(root_url) 
			else
				flash[:error] = "Login failed: check username/password combination." and redirect_to(login_url)
			end
		end
	end
	
	def index
    @applications = Application.all
  end
  
  def show
    @application = Application.find(params[:id])
		respond_to do |wants|
			wants.json { @application.to_json }
		end
  end
  
  def new
    @application = Application.new
  end
  
  def create
    @application = Application.new(params[:application])
    if @application.save
      flash[:notice] = "Successfully created application."
      redirect_to @application
    else
      render :action => 'new'
    end
  end
  
  def edit
    @application = Application.find(params[:id])
  end
  
  def update
    @application = Application.find(params[:id])
    if @application.update_attributes(params[:application])
      flash[:notice] = "Successfully updated application."
      redirect_to @application
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @application = Application.find(params[:id])
    @application.destroy
    flash[:notice] = "Successfully destroyed application."
    redirect_to applications_url
  end
end
