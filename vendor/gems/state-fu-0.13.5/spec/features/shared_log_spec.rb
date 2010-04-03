require File.expand_path("#{File.dirname(__FILE__)}/../helper")

describe "using StateFu w/ shared logs" do
  it "should be sane" do
    StateFu::Logging.shared?.should == false
  end
end
