require File.expand_path("#{File.dirname(__FILE__)}/../helper")

module MySpecHelper
  module BindingExampleHelper

    attr_accessor :ok

    def helper_method
    end

    def requirement_satisfier?
      true
    end

    def requirement_satisfier_with_arg?( t )
    end
  end

  module OtherExampleHelper
    def other_helper_method
    end

    def other_requirement_satisfier?
      true
    end
  end
end

describe "extending bindings and transitions with Lathe#helper" do

  include MySpecHelper

  before(:each) do
    reset!
    make_pristine_class('Klass')
    Klass.class_eval do
      attr_accessor :ok
    end

    @machine = Klass.state_fu_machine do
      helper MySpecHelper::BindingExampleHelper
      helper 'my_spec_helper/other_example_helper'

      chain "a -a2b-> b -b2c-> c"

      events.each do |e|
        e.requires :requirement_satisfier?
        e.requires :requirement_satisfier_with_arg?
        e.requires :other_requirement_satisfier?
      end
    end

    @other_machine = Klass.state_fu_machine(:other) do
      helper ::MySpecHelper::OtherExampleHelper
    end
    @obj = Klass.new
    @binding       = @obj.state_fu
    @other_binding = @obj.other
    @transition    = @obj.state_fu.transition(:a2b)
  end # before

  #
  #

  describe "binding" do
    describe "instance methods" do

      it "should respond to helper_method" do
        @binding.should respond_to( :helper_method)
      end


      it "should respond to other_helper_method" do
        @binding.should respond_to( :other_helper_method)
      end

      it "should respond to requirement_satisfier?" do
        @binding.should respond_to( :requirement_satisfier?)
      end

      it "should respond to other_requirement_satisfier?" do
        @binding.should respond_to( :other_requirement_satisfier?)
      end

    end
  end

  describe "transition" do
    describe "instance methods" do

      it "should respond to helper_method" do
        @transition.should respond_to( :helper_method)
      end

      it "should respond to other_helper_method" do
        @transition.should respond_to( :other_helper_method)
      end

      it "should respond to requirement_satisfier?" do
        @transition.should respond_to( :requirement_satisfier?)
      end

      it "should respond to other_requirement_satisfier?" do
        @transition.should respond_to( :other_requirement_satisfier?)
      end

    end
  end

end

