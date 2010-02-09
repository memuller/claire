require File.dirname(__FILE__) + '/../spec_helper'

describe Subcategory do
  it "should be valid" do
    Subcategory.new.should be_valid
  end
end
