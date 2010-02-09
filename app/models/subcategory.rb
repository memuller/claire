class Subcategory
  include MongoMapper::Document
  key :name, String, :required => true
  key :description, String
  
  belongs_to :category
  key :category_id, ObjectId
end
