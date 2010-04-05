@item_type = :videos unless @item_type
xml.channel do |xml|
	if @category
		xml.title @category.name
		xml.description @category.description
		xml.header @category.image_url if @category.image_url		
		xml.tag! "num_#{@item_type.to_s}", @category.send("num_#{@item_type.to_s}")
		xml.link category_url @category
	else
		xml.title "Project St. Claire - Searching for #{@item_type.to_s} matching: #{@search_terms}"
	end
	items = render(:partial => "#{@item_type}/show", :collection => @results, :as => @item_type, :format => 'xml', :locals => {:full => false})      
	xml << items if items
	 	
	xml.atom:link, :rel => "previous", :href => @previous_url if @previous_url
	xml.atom:link, :rel => "next", :href => @next_url if @next_url
	
end