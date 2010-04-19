# Be sure to restart your server when you modify this file
# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  
  # config.load_paths += %W( #{RAILS_ROOT}/extras )
  
  # == DEPENDENCIES GALLORE
  MONGO_VERSION = "0.19.3" and RSPEC_VERSION = "1.2.9"
	#mongodb stuff and mappers
		config.gem "mongo", :version => MONGO_VERSION
	  # config.gem "mongo_ext", :lib => false, :version => MONGO_VERSION
		# mongo_ext is SERIOUSLLY BUGGED ON OSX. TODO: add a trigger that enables it
		# on non-darwin kernels.  
		config.gem "mongo_mapper", :version => "0.7.3" 
  #state-machine-like controll for video workers.
		config.gem "state-fu"
	#handles file uploads. 
	  config.gem "paperclip"   
	#rspec and testing stuff
		config.gem "rspec", :lib => false, :version => RSPEC_VERSION
	  config.gem "rspec-rails", :lib => false, :version => RSPEC_VERSION
	  config.gem 'factory_girl'
	# performance increase for workling/starling
	  config.gem "system_timer", :lib => false   
	#rvideo and its pal, flvtool
	  config.gem "rvideo-tecnobrat", :lib => "rvideo"
	  config.gem "flvtool2", :lib => false
  #for youtube video publishing
		config.gem "youtube-g", :lib => "youtube_g"   
  #password hashing
		config.gem 'bcrypt-ruby', :lib => "bcrypt" 	
	#those guys aren't needed here, but without them,
	#other parts of the system will fail.
		config.gem "god", :lib => false
		config.gem "starling", :lib => false
		
  #config.frameworks -= [ :active_record ]
  #config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de

end