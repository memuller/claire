class Tag
  include MongoMapper::Document
  
  key :name, String, :required => true
  key :items, Array, :default => []
  key :weight, Integer, :default => 0
  
  def videos
    videos = []
    items.each do |item_id|
      unless (video = Video.find item_id).nil?
        videos << video
      end
    end
    videos
  end
  
  def add_to video
    video = Video.find(video) unless video.is_a?(Video)
    video.tags << name and video.save! unless video.tags.include? name
    items << video.id and save! unless items.include? video.id
    
  end
  
  def self.set_tag tag_name, video
    tag = Tag.find_by_name tag_name
    tag = Tag.new(:name => tag_name) if tag.nil?
    tag.add_to video
  end
    
   
  
end