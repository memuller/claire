require File.dirname(__FILE__) + '/../spec_helper'

describe Program do
  it "should be valid" do
    Program.new.should be_valid
  end
end
