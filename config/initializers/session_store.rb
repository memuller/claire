# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_iptv_session',
  :secret      => '915f50a23f932e71f00b7a8c40cdc8727459b04a8b48eb8bada7ce0c74cc00b3c1cc36ce94c9a8ebfb52a30fa5708aaa83bae421ad4c52de79abb7bcf31d0f95'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
