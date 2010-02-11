require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
#small helper to check instance state 
def state_okay? object, state
  object.state.should == state
end

describe Video do
      
  context "in its initialized state" do
    before(:all) do
      @video = Video.new
    end
    it "should be in the initialized state" do
      
    end
    it "should have title"
    it "should have tags"
    it "should have categories"
    it "should have desired formats"
  end
  
  context "in its video_uploaded state" do
    it "should be in the video_uploaded state"
    it "should have a video_path"
    it "video_path should be valid file"
    it "should have a size attribute"
    it "should have a format_okay? attribute"
    context "based on format_okay? value" do
      it "should transition to thumbnailing if it's true"
      it "should transition to error if it's false"
    end
  end
  
  context "while thumbnailing" do
    it "should be in the thumbnailing state"
    it "should have a method that captures thumbnails"
    it "should produce three thumbnails"
    context "its thumbnails attribute" do
      it "should be an array"
      it "if non-empty, should contain valid public URLs for thumbnails"
    end
    context "based on thumbnails_okay? value" do
      it "should transition to converting if it's true"
      it "should transition to error if it is false"
    end
  end
  
  context "while converting" do
    it "should be in the converting state"
    it "should have an array of formats to convert to"
    it "should go to the archiving state if there are no formats to convert to"
    it "should spawn an converter for each format"
    describe "its conversion_okay? method" do
      it "should not be okay if there are no converted files"
      it "should not be okay if there are erros on the rvideo converter response"
      it "should not be okay if an rvideo inspector can't inspect the files"
      it "should be okay otherwise"
      it "should transition to publishing if it's okay"
      it "should transition to error otherwise"
    end
  end
  
  context "while on the publishing state" do
    it "should have an publish_to array"
    describe "the move publisher" do
      it "should move files to the desired path"
    end
    describe "the Youtube publisher" do
      it "still a draft"
    end
    
  end
  
  
  
  
  
end     