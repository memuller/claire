require File.expand_path("#{File.dirname(__FILE__)}/../helper")

describe "extending bindings and transitions with Lathe#helper" do

  include MySpecHelper

  before(:each) do
    reset!
    make_pristine_class('Klass')

    @machine = Klass.state_fu_machine do
      state :normal, :colour => 'green'
      state :bad,    :colour => 'red'
      event( :worsen, :colour => 'orange' ) { from :normal => :bad }
    end
    @obj = Klass.new
    @binding       = @obj.state_fu

  end # before

  describe "accessing sprocket options" do
    describe "state#[]" do
      it "should return state.options[key]" do
        @machine.states[:normal][:colour].should == 'green'
      end
    end
    describe "event#[]" do
      it "should return event.options[key]" do
        @machine.events[:worsen][:colour].should == 'orange'
      end
    end

    describe "state#[]=" do
      it "should update state.options" do
        @machine.states[:normal][:flavour] = 'lime'
        @machine.states[:normal][:flavour].should == 'lime'
      end
    end
    describe "event#[]=" do
      it "should update event.options" do
        @machine.events[:worsen][:flavour] = 'orange'
        @machine.events[:worsen][:flavour].should == 'orange'
      end
    end

  end
end
