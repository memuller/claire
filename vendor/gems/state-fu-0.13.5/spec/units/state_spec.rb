require File.expand_path("#{File.dirname(__FILE__)}/../helper")

## See state_and_event_common_spec.rb for behaviour shared between
## StateFu::State and StateFu::Event
##

describe StateFu::State do
  include MySpecHelper

  before(:each) do
    @machine = Object.new
    @state   = StateFu::State.new( @machine, :flux, {:meta => "wibble"} )
  end

  describe "instance methods" do

    describe "#after?(other_state)" do
      
      it "should be true when the other state is is after? this one" do
        m = StateFu::Machine.new do
          states :red, :green, :yellow
        end
        m.states[:green].after?(:red).should be_true
        m.states[:green].after?(:yellow).should be_false
        m.states[:green].after?(:green).should be_false        
        m.states[:green].after?(m.states[:red]).should be_true
        m.states[:green].after?(m.states[:yellow]).should be_false
        m.states[:green].after?(m.states[:green]).should be_false        
      end
    end

    describe "##before?(other_state)" do
      
      it "should be true when the other state is is before this one" do
        m = StateFu::Machine.new do
          states :red, :green, :yellow
        end
        m.states[:green].before?(:red).should be_false
        m.states[:green].before?(:yellow).should be_true
        m.states[:green].after?(:green).should be_false        
        m.states[:green].before?(m.states[:red]).should be_false
        m.states[:green].before?(m.states[:yellow]).should be_true
        m.states[:green].after?(m.states[:green]).should be_false        
      end
    end

    describe "#events" do

      it "should call machine.events.from(self)" do
        machine_events = Object.new
        @machine.should_receive(:events).and_return machine_events
        machine_events.should_receive(:from).with(@state).and_return nil
        @state.events
      end

    end

  end
end
