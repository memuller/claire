require File.dirname(__FILE__) + '/../spec_helper'
 
describe StreamsController do
  integrate_views
  
  # it "index action should render index template" do
  #    get :index
  #    response.should render_template(:index)
  #  end
  #  
  #  it "show action should render show template" do
  #    get :show, :id => Stream.first
  #    response.should render_template(:show)
  #  end
  #  
  #  it "new action should render new template" do
  #    get :new
  #    response.should render_template(:new)
  #  end
  #  
  #  it "create action should render new template when model is invalid" do
  #    Stream.any_instance.stubs(:valid?).returns(false)
  #    post :create
  #    response.should render_template(:new)
  #  end
  #  
  #  it "create action should redirect when model is valid" do
  #    Stream.any_instance.stubs(:valid?).returns(true)
  #    post :create
  #    response.should redirect_to(stream_url(assigns[:stream]))
  #  end
  #  
  #  it "edit action should render edit template" do
  #    get :edit, :id => Stream.first
  #    response.should render_template(:edit)
  #  end
  #  
  #  it "update action should render edit template when model is invalid" do
  #    Stream.any_instance.stubs(:valid?).returns(false)
  #    put :update, :id => Stream.first
  #    response.should render_template(:edit)
  #  end
  #  
  #  it "update action should redirect when model is valid" do
  #    Stream.any_instance.stubs(:valid?).returns(true)
  #    put :update, :id => Stream.first
  #    response.should redirect_to(stream_url(assigns[:stream]))
  #  end
  #  
  #  it "destroy action should destroy model and redirect to index action" do
  #    stream = Stream.first
  #    delete :destroy, :id => stream
  #    response.should redirect_to(streams_url)
  #    Stream.exists?(stream.id).should be_false
  #  end                                             
end
