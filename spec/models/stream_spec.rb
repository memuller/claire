require File.dirname(__FILE__) + '/../spec_helper'

describe Stream do
  it "should require title and url" do
    Stream.new.should_not be_valid
		Stream.create(:title => "testing", :url => "http://testing").should be_valid
  end
	it "should have an okay attribute, defaulting to true" do
		Stream.new.okay?.should be true
	end
	
	it "should have an category_name, if it is an category member" do
		category = Category.create! :name => "test"
		stream = Factory.create(:valid_stream, :category => category)
		stream.category_name.should == category.name		
	end
	
	describe "schedule options" do
		it "should have a current_program property"
		it "should have an next_program property"
		context "when there's no current or next program on this time" do
			it "those methods should find the current and next program"			
			it "current program should be set if its found"
			context "when there's no current program to be found" do
				it "should leave it as nil"
				it "should set a timer to check the current program again, this time being when the next program begins"
				it "this time cannot exceed 10 hours"
				it "if there's no next program, this time should be set to 10 hours"
			end			 
				
		end
	end
end
