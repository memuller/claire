require File.expand_path("#{File.dirname(__FILE__)}/../helper")

##
##
##

describe "Adding events to a Machine outside a state block" do

  include MySpecHelper

  describe "When there is an empty machine" do
    before do
      reset!
      make_pristine_class 'Klass'
      Klass.state_fu_machine() { }
    end

    describe "calling Klass.state_fu_machine().events" do
      it "should return []" do
        Klass.state_fu_machine().events.should == []
      end
    end

    describe "calling event(:die){ from :dead, :to => :alive } in a Klass.state_fu_machine()" do
      before do
        Klass.state_fu_machine do
          event :die do # arity == 0
            from :dead, :to => :alive
          end
        end
      end

      it "should require a name when calling machine.event()" do
        lambda { Klass.state_fu_machine(){ event {} } }.should raise_error(ArgumentError)
      end

      it "should add 2 states to the machine called: [:dead, :alive] " do
        Klass.state_fu_machine.state_names.should == [:dead, :alive]
        Klass.state_fu_machine.states.length.should == 2
        Klass.state_fu_machine.states.each { |s| s.should be_kind_of(StateFu::State) }
        Klass.state_fu_machine.states.map(&:name).sort.should == [:alive, :dead]
      end

      describe "the <StateFu::Event> created" do
        it "should be accessible through Klass.state_fu_machine.events" do
          Klass.state_fu_machine.events.should be_kind_of(Array)
          Klass.state_fu_machine.events.length.should == 1
          Klass.state_fu_machine.events.first.should be_kind_of( StateFu::Event )
          Klass.state_fu_machine.events.first.name.should == :die
        end
      end

    end

    # arity of blocks is optional, thanks to magic fairy dust ;)
    describe "calling event(:die){ |s| s.from :dead, :to => :alive } in a Klass.state_fu_machine()" do
      before do
        Klass.state_fu_machine do
          event :die do |s|
            s.from :dead, :to => :alive
          end
        end
      end

      it "should add 2 states to the machine called [:dead, :alive] " do
        Klass.state_fu_machine.state_names.should == [:dead, :alive]
        Klass.state_fu_machine.states.length.should == 2
        Klass.state_fu_machine.states.each { |s| s.should be_kind_of( StateFu::State ) }
      end
    end

  end
end

