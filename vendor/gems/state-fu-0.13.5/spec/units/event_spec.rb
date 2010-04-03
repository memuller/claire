require File.expand_path("#{File.dirname(__FILE__)}/../helper")

##
##
##

describe StateFu::Event do
  include MySpecHelper
  before do
    @machine = Object.new
    @machine.should_receive(:tools).any_number_of_times.and_return [].extend(StateFu::ToolArray)
  end

  describe "Instance methods" do
    before do
      @name         = :germinate
      @options      = {:speed => :slow}
      @event        = StateFu::Event.new( @machine, @name, @options )
      @state_a      = StateFu::State.new( @machine,:a )
      @state_b      = StateFu::State.new( @machine,:b )
      @initial      = Object.new
      @final        = Object.new
      @start        = Object.new
      @end          = Object.new
    end


    describe "Instance methods" do
      describe "setting origin / target" do

        describe "target" do
          it "should be nil if targets is nil" do
            @event.should_receive(:targets).and_return nil
            @event.target.should == nil
          end

          it "should be nil if targets has more than one state" do
            @event.should_receive(:targets).at_least(1).times.and_return [@state_a, @state_b]
            @event.target.should == nil
          end

          it "should be the sole state if targets is set and there is only one" do
            @event.should_receive(:targets).at_least(1).times.and_return [@state_a]
            @event.target.should == @state_a
          end
        end

        describe 'origins=' do
          it "should call get_states_list_by_name with its argument" do
            @machine.should_receive(:find_or_create_states_by_name).with(:initial).and_return []
            @event.origins= :initial
          end

          it "should set @origin to the result" do
            @machine.should_receive(:find_or_create_states_by_name).with(:initial).and_return [:result]
            @event.origins= :initial
            @event.origins.should == [:result]
          end

        end

        describe 'targets=' do
          it "should call get_states_list_by_name with its argument" do
            @machine.should_receive(:find_or_create_states_by_name).with(:initial).and_return []
            @event.targets= :initial
          end

          it "should set @target to the result" do
            @machine.should_receive(:find_or_create_states_by_name).with(:initial).and_return [:result]
            @event.targets= :initial
            @event.targets.should == [:result]
          end
        end

        describe "lathe" do
          before do
            @lathe = @event.lathe()
          end

          it "should return a StateFu::Lathe" do
            @lathe.should be_kind_of( StateFu::Lathe )
          end

          it "should have the event's machine" do
            @lathe.machine.should == @event.machine()
          end

          it "should have the event as the sprocket" do
            @lathe.state_or_event.should == @event
          end

        end

        describe '.from()' do
          describe "given @event.from :initial, :to => :final" do
            describe "setting attributes" do
              before do
                @machine.should_receive(:find_or_create_states_by_name).with(:initial).and_return [@initial]
                @machine.should_receive(:find_or_create_states_by_name).with(:final).and_return [@final]
                
                # stub( @machine ).find_or_create_states_by_name( anything ) { |*a| raise(a.inspect) }
                # stub( @machine ).find_or_create_states_by_name( :initial ) { [@initial] }
                # stub( @machine ).find_or_create_states_by_name( :final   ) { [@final]   }
              end

              it "should call @machine.find_or_create_states_by_name() with :initial and :final" do
                @event.from :initial, :to => :final
              end

              it "should set @event.origin to the returned array of origin states" do
                @event.from :initial, :to => :final
                @event.origins.should == [@initial]
              end

              it "should set @event.target to the returned array of target states" do
                @event.from :initial, :to => :final
                @event.targets.should == [@final]
              end
            end
          end

          describe "given @event.from <Array>, :to => <Array>" do
            it "should call @machine.find_or_create_states_by_name() with both arrays" do
              @machine.should_receive(:find_or_create_states_by_name).with(:initial, :start).and_return [@initial, @start]
              @machine.should_receive(:find_or_create_states_by_name).with(:final, :end).and_return [@final, @end]
              @event.from( [:initial, :start], :to => [:final, :end] )
            end
          end

          describe "given @event.from :ALL, :to => :ALL" do
            it "should set origins and targets to @machine.states" do
              @machine.should_receive(:states).any_number_of_times.and_return [:all, :of, :them]
              @event.from( :ALL, :to => :ALL )
              @event.origins.should == [:all, :of, :them ]
              @event.targets.should == [:all, :of, :them ]
            end
          end

        end

        describe '.to()' do
          describe "given :final" do
            it "should set @event.target to machine.find_or_create_states_by_name( :final )" do
              @machine.should_receive(:find_or_create_states_by_name).with(:final).and_return [@final]
              @event.to :final
              @event.targets.should == [@final]
            end
          end
        end

      end

      describe 'origin_names' do
        it "should return an array of state names in origin when origin is not nil" do
          @machine.should_receive(:find_or_create_states_by_name).with(:initial).and_return [@initial]
          @machine.should_receive(:find_or_create_states_by_name).with(:final).and_return [@final]
          @event.from :initial, :to => :final
          @event.origin.should == @initial
          @initial.should_receive(:to_sym).any_number_of_times.and_return(:initial)
          @event.origin_names.should == [:initial]
        end

        it "should return nil when origin is nil" do
          @event.should_receive(:origins).any_number_of_times.and_return nil
          @event.origin_names.should == nil
        end

      end

      describe 'target_names' do
        it "should return an array of state names in target when target is not nil" do
          @event.should_receive(:targets).any_number_of_times.and_return [@final]
          @final.should_receive(:to_sym).any_number_of_times.and_return(:final)          
          @event.target_names.should == [:final]
        end

        it "should return nil when target is nil" do
          @event.should_receive(:targets).any_number_of_times.and_return nil
          @event.target_names.should == nil
        end
      end

      describe 'to?' do
        it "should return true given a symbol which is the name of a state in @target" do
          @event.should_receive(:targets).any_number_of_times.and_return [StateFu::State.new(@machine,:a)]          
          @event.to?( :a ).should == true
        end

        it "should return false given a symbol which is not the name of a state in @target" do
          @event.should_receive(:targets).any_number_of_times.and_return [StateFu::State.new(@machine,:a)]          
          @event.to?( :b ).should == false
        end
      end

      describe 'from?' do
        it "should return true given a symbol which is the name of a state in @origin" do
          @event.should_receive(:origins).any_number_of_times.and_return [StateFu::State.new(@machine,:a)]          
          @event.from?( :a ).should == true
        end

        it "should return nil given a symbol which is not the name of a state in @origin" do
          @event.should_receive(:origins).any_number_of_times.and_return [StateFu::State.new(@machine,:a)]          
          @event.from?( :b ).should == nil
        end
      end

    end # describe instance methods
  end   # describe StateFu::Event
end
