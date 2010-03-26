video = @video unless video
params[:full] = true unless params[:full] == false 
xml.item do
	xml.title		video.title
	xml.link		video_url video
	#here goes the contet itself
	debugger
	unless video.formats.empty?
		video.formats.each do |v|
			xml.tag! "media:content", :url => video.encoded_video_url(v), 
														:type => "video/flv", 
														:duration => video.duration
		end  	
	end
	
	#shows all thumbnails or just the default one												 
  if params[:full]
		video.video.styles.each do |thumb|
			w, h = thumb[1][:geometry].split("x")
			xml.tag! "media:thumbnail", :url => video.thumbnail_url(thumb[0]), :width => w, :heigth => h
		end
	else
  	xml.tag! "media:thumbnail", :url => video.thumbnail_url, :type => "image/jpeg"
	end
	
	#video general info
	xml.tag! "media:category",			:label => video.category.name 
	xml.tag! "media:keywords",			video.tags.join(", ")
	xml.tag! "media:description",		params[:full] ? video.description : video.short_description
	
	xml.tag! "media:community" do
		xml.tag! "media:starRating",	:average => video.rating
		xml.tag! "media:statistics",	:views => video.num_views 
	end
	
	#shows related items if display mode is full
	if params[:full]
		xml.related do
			video.related.each do |item|
				xml.item :link => video_url(item), :thumbnail => item.thumbnail_url(:thumb_square), 
					:title => item.title
			end
		end
  end			
end
