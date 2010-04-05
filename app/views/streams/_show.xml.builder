stream = @stream unless stream
params[:full] = true unless params[:full] == false 
xml.item do |v|
	xml.title		stream.title
	xml.link		stream_url stream
	xml.url			stream.url
	xml.format	stream.format
	
	#video general info
	#xml.tag! "media:category",			:label => stream.category.name 
	#xml.tag! "media:keywords",			stream.tags.join(", ")
	xml.tag! "media:description",		params[:full] ? stream.description : stream.short_description
	
	xml.tag! "media:community" do
		#xml.tag! "media:statistics",	:views => stream.num_views 
	end

end
