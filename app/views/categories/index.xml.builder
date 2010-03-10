@categories.each do |item|
	xml.item do
  	xml.title item.name
		xml.description(item.description) if item.description
		xml.num_videos item.num_videos
	end
end
