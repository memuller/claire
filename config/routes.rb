ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'videos' 
  
  #map.connect 'app/:appname/:klass/:kaction.:format', :controller => :applications, :action => :redirector
	#map.connect 'app/:appname/:klass.:format', :controller => :applications, :action => :redirector, :
	map.search_videos 'videos/search/.:format', :controller => :videos, :action => 'search' 
	map.search_streams 'streams/search/.:format', :controller => :streams, :action => 'search'
	#video aliased urls
	map.top_rated_videos 'videos/top_rated/.:format', :controller => :videos, :action => 'top_rated'
	map.most_viewed_videos 'videos/most_viewed/.:format', :controller => :videos, :action => 'most_viewed'
	map.special_videos 'videos/specials/.:format', :controller => :videos, :action => 'specials'   
	
	#user authentication control
	map.logout 'logout', :controller => 'applications',	:action => 'logout'
	map.login 'login', :controller => 'applications', :action => 'login' 
	
	map.resources :videos
  map.resources :streams
  map.resources :subcategories
  map.resources :categories
  map.resources :applications
  map.resources :programs

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
