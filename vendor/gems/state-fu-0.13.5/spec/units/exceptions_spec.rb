require File.expand_path("#{File.dirname(__FILE__)}/../helper")

module MockTransitionHelper
  def mock_transition
    transition = Object.new()
    # hmm, seems we have to stub #binding ourselves ...
    transition.instance_eval do
      (class << self; self; end).class_eval do
        def binding
          @binding ||= Object.new
        end        
      end
    end
    transition
  end
end

describe StateFu::RequirementError do
  include MockTransitionHelper

  describe "constructor" do
    before do
      @transition = mock_transition
    end

    it "should create an exception given a transition" do
      e = StateFu::RequirementError.new(@transition)
      e.should be_kind_of(StateFu::RequirementError)
    end
    
    it "should become an array of requirement messages with #to_a" do
      e = StateFu::RequirementError.new(@transition)
      e.should be_kind_of(StateFu::RequirementError)
      @transition.should_receive(:unmet_requirement_messages).and_return(['oshit'])
      e.to_a.should == ['oshit']
    end
  end
end

describe StateFu::TransitionHalted do
  include MockTransitionHelper

  describe "constructor" do
    before do
      @transition = mock_transition
    end

    it "should create a TransitionHalted given a transition" do
      e = StateFu::TransitionHalted.new( @transition )
      e.should be_kind_of( StateFu::TransitionHalted )
    end

    it "should allow a custom message" do
      msg = 'helo'
      e = StateFu::TransitionHalted.new( @transition, msg )
      e.should be_kind_of( StateFu::TransitionHalted )
      e.message.should == msg
    end

    it "should allow a message to be omitted" do
      e = StateFu::TransitionHalted.new( @transition )
      e.should be_kind_of( StateFu::TransitionHalted )
      e.message.should == "StateFu::TransitionHalted"
    end

    it "should allow access to the transition" do
      e = StateFu::TransitionHalted.new( @transition )
      e.transition.should == @transition
    end
  end
end

describe StateFu::IllegalTransition do
  include MockTransitionHelper

  before do
    @transition = mock_transition
  end

  describe "constructor" do
    it "should create an IllegalTransition given a transition" do
      e = StateFu::IllegalTransition.new( @transition)
      e.should be_kind_of( StateFu::IllegalTransition )
      e.transition.should == @transition
      e.message.should == "StateFu::IllegalTransition"
    end    

    it "should allow a custom message" do
      e = StateFu::IllegalTransition.new( @transition, 'danger' )
      e.should be_kind_of( StateFu::IllegalTransition )
      e.transition.should == @transition
      e.message.should == 'danger'
    end

    it "should allow access to a list of valid transitions if provided" do
      e = StateFu::IllegalTransition.new( @transition, 'danger', [:a, :b] )
      e.should be_kind_of( StateFu::IllegalTransition )
      e.legal_transitions.should == [:a, :b]
    end
  end
end
