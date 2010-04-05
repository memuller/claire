class Application
  include MongoMapper::Document
	
	key :alias, String, :required => true
	key :name, String, :required => true
	key :description, String
	key :username, String, :required => true
	key :password, String, :required => true
	key :api_key, String
	
	# those are going to be used if the pal is logged in
	key :session_type, String
	key :logged, Boolean, :default => false
	key :actions_until_reset, Integer, :default => 200
	
	# kind of itens that can be owned
	key :can_own, Array, :default => %w(streams videos categories subcategories)
	
	# before_save item hooks:
	# - generates an API key if we don't have one.
	# - hashes the password if it doesn't look to be an hash. Note this is NOT failproof.
	before_save lambda { |item| 
		item.generate_api_key! unless @api_key
		BCrypt::Password.new(item.password) rescue item.hash_password!
	}
	
	# authenticates an user, if possible
	def self.auth controller
		if controller.session[:user_id]
			user = self.find(controller.session[:user_id])
			controller.instance_variable_set("@current_user", user) and success = true if user   										
		else
			if self.by_password? controller 
				success = self.authenticate_by_password controller
			elsif self.by_api? controller  
				success = self.authenticate_by_api_key controller
			end
		end
		
		unless success
			if self.by_api? controller		
				controller.send :render, :text => "Authentication failed.", :status => 403
			else
				controller.send :redirect_to, :url => login_url if controller.force_auth
			end
		else
			
			# if the user is auth'ed, the request is a post, and on an object this user can own,
			# stores this user_id along with the object by merging it on the params.
			klass_name = controller.class.to_s.sub("Controller", "").downcase
			if controller.current_user and controller.current_user.can_own.include?(klass_name) and controller.request.method == :post
				controller.params[klass_name.singularize].merge!({ "owner_id" => controller.current_user.id })
			end
			
		end
	end
	
	# checks if api-based auth is being performed or desired
	def self.by_api? controller
		controller.params[:api_key] and not controller.params[:username] and not controller.params[:password]				
	end
	
	# checks if password-based auth is being performed or desired
	def self.by_password? controller
		controller.params[:username] and controller.params[:password] and not controller.params[:api_key]
	end
	
	# find an user by its username, and checks its password
	def self.authenticate_by_password controller
		return false unless user = self.find_by_username(controller.params[:username])
		if user.password_match? controller.params[:password]
			controller.session[:user_id] = user.id and return true
		else
			false
		end
	end
	
	# finds an user by its api_key
	def self.authenticate_by_api_key controller
		return false unless user = self.find_by_api_key(controller.params[:api_key])
		controller.session[:user_id] = user.id and return true
	end
	
	# overwrites current password with its hash
	def hash_password!
		@password = BCrypt::Password.create(@password) 	
	end
	
	# checks if given password matches with the user's
	def password_match? password
		BCrypt::Password.new(@password) == password
	end
	
	# generates and saves an random API key
	def generate_api_key!
		@api_key = Digest::SHA1.hexdigest((Time.now.to_f + rand(100) * rand()).to_s) 
	end
	
end
