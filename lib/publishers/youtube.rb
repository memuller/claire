module Publishers
	class Youtube
		
		# requirements
		require 'net/http' 
		require 'net/https' 
		require 'rexml/document' 
		
		# URL-building constants
		AUTH_HOST = "www.google.com"
		UPLOAD_HOST = 'uploads.gdata.youtube.com'		
		AUTH_PATH = '/youtube/accounts/ClientLogin'
		UPLOAD_PATH = "/feeds/api/users/username/uploads"
		
		# objects accessor methods
		attr_accessor :username, :password, :api_key, :video, :category
		attr_reader :token
		
		def initialize args={}
			unless args[:video].is_a? Video and args[:username] and args[:password] and args[:api_key]
				raise ArgumentError, "Requires username, password, api_key and a valid video."
			end
			raise ArgumentError, "Username should be an google email, not an youtube user" unless args[:username].include? "@"
			args.each{ |k,v| instance_variable_set "@#{k}", v }			
			#auths
			get_auth_token			
		end
		
		# actually POSTs the upload request. 
		# - on success: returns true and assigns an youtube video id
		# - on failure: returns an array of errors
		def publish!
			read_video
			@boundary_string = "f93dcbA3" 
			request_body = build_upload_request
			http = Net::HTTP.new UPLOAD_HOST
			
		  request_headers = {
				'X-GData-Key' => "key=#{@api_key}",
		  	'Slug' => @video_file_name,
		  	'Content-Type' => %(multipart/related; boundary="#{@boundary_string}"),
		  	'Content-Length' => request_body.length.to_s,
		  	'Connection' => 'close',
		  	'Authorization' => "GoogleLogin auth=#{@token}"
		  }
		
      response, body = retryable :tries => 3 do
      	http.post( UPLOAD_PATH.sub('username', @youtube_user.to_s), request_body, request_headers )
      end		  
      
			if response.code == '201'
				xml = REXML::Document.new body
				video_id = xml.elements['entry'][0].text.split('/').last
      	@video.update_attributes :youtube_id => video_id
				@video.save!
				LOGGER.ok "Published video #{@video.id} to Youtube as #{video_id}."
				return true
			else			
				return "Youtube upload failed with status code #{response.code}. \n Response body: \n #{response.body}" 
      end
		end
		
		# reads the video raw file; returns its filename and it's content as string.
		def read_video
			@video_file_content = File.open(@video.uploaded_file_path, 'r'){ |io| io.read }
			@video_file_name = @video.uploaded_file_path.split("/").last			
		end
		
		# returns an upload request to be POST'ed
		def build_upload_request
request = <<"DATA"
--#{@boundary_string}		
Content-Type: application/atom+xml; charset=UTF-8

<?xml version="1.0"?>
<entry xmlns="http://www.w3.org/2005/Atom"
  xmlns:media="http://search.yahoo.com/mrss/"
  xmlns:yt="http://gdata.youtube.com/schemas/2007">
  <media:group>
    <media:title type="plain"> #{@video.title} </media:title>
    <media:description type="plain"> #{@video.description} </media:description>
    <media:category scheme="http://gdata.youtube.com/schemas/2007/categories.cat">People
    </media:category>
    <media:keywords> #{@video.tags.join(", ")} </media:keywords>
  </media:group>
</entry>
--#{@boundary_string}
Content-Type: #{@video.video_content_type}
Content-Transfer-Encoding: binary

#{@video_file_content}
--#{@boundary_string}--
DATA
			request
		end
		
		# returns an GData ClientAuth token for the specified user.
		# also sets @youtube_user with the youtube user for the given G.Account.
		def get_auth_token 
			# new http request; sends login info as url params and a simple header
			http = Net::HTTP.new(AUTH_HOST, 443); http.use_ssl = true
			data = "Email=#{@username}&Passwd=#{@password}&service=youtube&source=Claire"
			headers = {'Content-Type' => 'application/x-www-form-urlencoded'}
			# a dumb retry block
			tries = 0
			begin
				response, data = http.post AUTH_PATH, data, headers
			rescue
				tries += 1
				if tries < 3
					retry
				else
					raise "Exceded maximum number of retries for auth request. Possibly, the server is quite busy."
				end
			end  
      
			# if response code was OK, return the auth token
			if response.code == '200'
				@token = data.scan /Auth=(.*)/
			  @youtube_user = data.scan /YouTubeUser=(.*)/
			  return @token
			else
				raise ArgumentError, "Invalid login credentials provided; GData tells you that: #{data}"
			end
		end
			
	end
end