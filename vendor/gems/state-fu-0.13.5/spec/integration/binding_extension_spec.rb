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

    describe "lathe.helper" do
      it "should add the arguments to the machine's collection of helpers" do
        @machine.should respond_to(:helpers)
        @machine.helpers.should be_empty
        @machine.lathe do
          helper :bench_grinder
        end
        @machine.helpers.should_not be_empty
        @machine.helpers.should include(:bench_grinder)
      end

      it "should extend the binding with the helper's methods" do
        @machine.lathe do
          helper :bench_grinder
        end
        @machine.helpers.should include(:bench_grinder)
        @obj = Klass.new
        @obj.state_fu.should respond_to(:snark)
      end
    end
  end
end
