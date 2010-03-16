# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
	private
	
	def get_status_code error_message
		code = error_message.match(/\(.*\)/)[0]
		code = code.gsub("(", "").gsub(")", "").strip
		code = code.to_i
		code
	rescue
		400
	end
	
	def set_search_terms
		@search_terms = ""
		params.to_a.each do |item|
			@search_terms += ", "
			@search_terms += item.join(" => ")
		end
	end
	
	def get_results
		@results = Search.new(params).results
	end
	
	def set_pagination
		params[:limit] = CONFIG['general']['per_page'] unless params[:limit]
		params[:page] = params[:page] ? params[:page].to_i : 1 
		raise "(404) Pages begin at 1, not 0." unless params[:page] >= 1		
		if params[:page] > 1
			@previous_url = request.url.sub(/(page)=(.*)/, '\1=' + (params[:page] - 1).to_s)
		end
		if request.url.include? 'page='
			@next_url = request.url.sub(/(page)=(.*)/, '\1=' + (params[:page] + 1).to_s)
		else
			starter = request.url.include?('?') ? '&' : '?'
			@next_url = request.url + "#{starter}page=#{params[:page] + 1}"
		end
	rescue Exception => e
		render :text => e.message, :status => get_status_code(e.message)
	end
end
