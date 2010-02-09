class Category
  include MongoMapper::Document
  key :name, String, :required => true
  key :description, String
  
  many :subcategories
end
