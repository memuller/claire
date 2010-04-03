require File.expand_path("#{File.dirname(__FILE__)}/../helper")

##
##
##

describe "Copying / cloning a Machine" do

  include MySpecHelper

  describe "a shallow copy" do
    before do
      reset!
      make_pristine_class("Klass")
      @original = Klass.state_fu_machine do
        state :a do
          event :goto_b, :to => :b
        end
      end
      @copy = @original.clone
    end

    # let's just test for strict object equality w/ equal? and call it a day

    it "should update an event's options in the original when it's changed in the copy" do
      @original.events[:goto_b].should be_equal @copy.events[:goto_b]
      @original.events[:goto_b].options.should be_equal @copy.events[:goto_b].options
    end   

    it "should update a state's options in the original when it's changed in the copy" do
      @original.states[:a].should be_equal @copy.states[:a]
      @original.states[:a].options.should be_equal @copy.states[:a].options
    end   

    it "should update the original when an event is added to the clone" do
      @original.events.should be_equal @copy.events
    end 

    it "should update the original when a state is added to the clone" do
      @original.states.should be_equal @copy.states
    end 

    it "should update the original with any changes to helpers" do
      @original.helpers.should be_equal @copy.helpers
    end
    
    it "should update the original with any changes to named_procs" do
      @original.named_procs.should be_equal @copy.named_procs
    end
    
    it "should update the original with any changes to requirement_messages" do
      @original.requirement_messages.should be_equal @copy.requirement_messages      
    end

  end # shallow

  describe "a deep copy" do
    before do
      reset!
      make_pristine_class("Klass")
      @original = Klass.state_fu_machine do
        state :a do
          event :goto_b, :to => :b
        end
      end
      @copy = @original.deep_copy()
    end

    it "should NOT update an event's options in the original when it's changed in the copy" do
      @original.events[:goto_b].should_not be_equal @copy.events[:goto_b]
      @original.events[:goto_b].options.should_not be_equal @copy.events[:goto_b].options
    end   

    it "should NOT update a state's options in the original when it's changed in the copy" do
      @original.states[:a].should_not be_equal @copy.states[:a]
      @original.states[:a].options.should_not be_equal @copy.states[:a].options
    end   

    it "should NOT update the original when an event is added to the clone" do
      @original.events.should_not be_equal @copy.events
    end 

    it "should NOT update the original when a state is added to the clone" do
      @original.states.should_not be_equal @copy.states
    end 

    it "should NOT update the original with any changes to helpers" do
      @original.helpers.should_not be_equal @copy.helpers
    end
    
    it "should NOT update the original with any changes to named_procs" do
      @original.named_procs.should_not be_equal @copy.named_procs
    end
    
    it "should NOT update the original with any changes to requirement_messages" do
      @original.requirement_messages.should_not be_equal @copy.requirement_messages      
    end

  end # deep

end
