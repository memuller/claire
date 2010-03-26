xml.channel do |xml|
	if @category
		xml.title @category.name
		xml.description @category.description
		xml.header @category.image_url
		xml.num_videos @category.num_videos
		xml.link category_url @category
	else
		xml.title "Project St. Claire - Searching for: #{@search_terms}"
	end
	items = render(:partial => 'videos/show', :collection => @results, :as => :video, :format => 'xml', :locals => {:full => false})      
	xml << items if items
	 	
	xml.atom:link, :rel => "previous", :href => @previous_url if @previous_url
	xml.atom:link, :rel => "next", :href => @next_url if @next_url
	
end