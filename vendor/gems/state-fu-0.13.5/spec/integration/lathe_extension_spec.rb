require File.expand_path("#{File.dirname(__FILE__)}/../helper")

module BenchGrinder
  def snark
  end
end

describe "extending StateFu::Lathe" do
  include MySpecHelper

  describe "helpers" do
    before do
      reset!
      make_pristine_class('Klass')
      @machine = Klass.state_fu_machine() do
        state :init
      end
    end # before

    describe "lathe.tool" do

      it "should add the arguments to the machine's collection of tools" do
        @machine.should respond_to(:tools)
        @machine.tools.should be_empty
        @machine.lathe do
          tool :bench_grinder
        end
        @machine.tools.should_not be_empty
        @machine.tools.should include(:bench_grinder)
      end

      it "should extend the machine's lathe" do
        @machine.lathe do
          tool :bench_grinder
          snark()
        end
        @machine.lathe.should respond_to( :snark )
        @machine.lathe.snark
      end

      it "should extend the machine's lathe for state and events" do
        @machine.lathe do
          tool :bench_grinder
          snark()
          state :grinding do
            snark()
            event :grind do
              snark()
            end
          end
        end
      end

      it "should not extend another machine's lathe" do
        @machine.lathe do
          tool :bench_grinder
          snark()
        end
        m2 = Klass.state_fu_machine(:two) do
        end
        lambda { m2.lathe.snark }.should raise_error( NoMethodError )
      end

    end # tool

  end
end
