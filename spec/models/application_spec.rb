require File.dirname(__FILE__) + '/../spec_helper'

describe Application do
  it "should have name, username, and password" do
    Application.new.should_not be_valid
		Application.create(:name => 'testing', :username => 'thingy', :password => 'none').should be_valid
  end
	it "should store an BCrypted password, instead of its raw" do
		pass = "testing password"
		item = Factory.build( :valid_app, :password => pass )
		item.password.should  pass
	end
	it "should have an valid API key" do
		item = Factory.build :valid_app
		item.api_key.should be_a_kind_of String
		item.api_key.should_not be_empty
	end
	
	describe "its auth method" do
		before :all do
			
		end
  	it "should receive username and password as parameters" do
  		lambda { Application.auth :username => "", :password => "" }.should_not raise_error
  	end
		it "should receive an api key as parameter" do
			lambda { Application.auth :api_key => "" }.should_not raise_error
		end
		it "should fail when provided with both api_key and username" do
			lambda { Application.auth :username => "", :password => "", :api_key => ""  }.should raise_error ArgumentError		
		end
		
		context	"user/password authentication" do
			it "on success, it should return an user_id" do
				app = Factory.create :valid_app, :password => "testing123"
				id = Application.auth(:username => app.username, :password => 'testing123')
				id.should_not be_nil
				Application.find(id).username.should == app.username				
			end
			it "should return false if user is not found or passwords don't match" do
				app = Factory.create :valid_app, :password => "testing123"
				Application.auth(:username => app.username, :password => 'testing').should be_false
			end
		end
		
		context "API authentication" do
			context "on expiring the API key" do
				it "the reset method should generate another API key" do
					item = Factory.build :valid_app
					old_key = item.api_key
					item.reset!
					item.api_key.should != old_key
					item.api_key.should_not be_empty
				end
				it "should have an requests_until_reset attribute, defaulting to 0"
				it "should reset the API after 200 requests"
				it "should clear the requests_until_reset after resetting"
			end
		end
  end	
end
