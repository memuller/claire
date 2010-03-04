video = @video unless video
xml.item do
	xml.title     		video.title
	
	#here goes the contet itself
	if video.done?
  	xml.tag! "media:content", :url => video.encoded_video_url(video.formats.first), 
													:type => "video/flv", 
													:duration => video.duration
	end
	#shows all thumbnails or just the default one												 
  if params[:all_thumbnails]
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
	xml.tag! "media:description",		video.short_description
	
	xml.tag! "media:community" do
		xml.tag! "media:starRating",	:average => video.rating
		xml.tag! "media:statistics",	:views => video.num_views 
	end			
end
