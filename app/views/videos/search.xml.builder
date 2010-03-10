xml.channel do
	if @category
		xml.title @category.name
		xml.description @category.description
	else
		xml.title "Project St. Claire - Searching for: #{@search_terms}"
	end
	
	xml.text!("#{render :partial => 'show', :collection => @results, :as => :video, :format => 'xml'}")	

	
	xml.atom:link, :rel => "previous", :href => @previous_url if @previous_url
	xml.atom:link, :rel => "next", :href => @next_url if @next_url
	
end