# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  
  # config.load_paths += %W( #{RAILS_ROOT}/extras )
  
  # == DEPENDENCIES GALLORE
  # mongo_mapper 0.6.10 works only with mongo 0.18.2; even thought there's a newer one
  MONGO_VERSION = "0.18.2" and RSPEC_VERSION = "1.2.9"
  config.gem "mongo", :version => MONGO_VERSION
  config.gem "mongo_ext", :lib => false, :version => MONGO_VERSION
  config.gem "mongo_mapper", :version => "0.6.10"
  config.gem "rspec", :lib => false, :version => RSPEC_VERSION
  config.gem "rspec-rails", :lib => false, :version => RSPEC_VERSION
  # performance increase for workling/starling
  config.gem "system_timer", :lib => false
  #rvideo and its pal, flvtool
  config.gem "tecnobrat-rvideo", :lib => "rvideo"
  config.gem "flvtool2", :lib => false
  
  config.frameworks -= [ :active_record ]

  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
end

#MONGO MAPPER CONFIGURATION BLOCK
MongoMapper.database = "iptv_#{RAILS_ENV}"
