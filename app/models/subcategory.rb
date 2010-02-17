class Subcategory
  include MongoMapper::EmbeddedDocument
  
	key :name, String, :required => true
  key :description, String


end
