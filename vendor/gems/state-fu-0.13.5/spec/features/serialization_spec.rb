require File.expand_path("#{File.dirname(__FILE__)}/../helper")

describe "serializing a state machine" do
  
  before do
    make_pristine_class('Document') do
      machine do
        states :draft, :published, :meta => {:isbn => 'snoo-factory'}
        
        state :draft do
          requires :working_title, :message => "What's it called?"      
          on_exit :bump_version
        end
                
        event :publish, :from => :draft, :to => :published, :meta => :wibble do          
          execute :generate_publicity
          requires :title, :message => "It needs a title"
        end
        initial_state :blank
      end
    end
    @machine = Document.machine
  end
  
  it 'should respond to #to_yaml' do
    @machine.should respond_to(:to_yaml)
  end
  
  describe "=> to_yaml" do
    before do
      @yaml = YAML.load(@machine.to_yaml)
    end
    
    it "should have states" do
      @yaml[:states].map{|s| s[:name] }.should == [:draft, :published, :blank]
    end
    
    it "should have an initial_state" do
      @yaml[:initial_state].should == :blank
    end
    
    it "should have events" do
      @yaml[:events].map{|e| e[:name] }.should == [:publish]
      @yaml[:events][0][:origins].should == [:draft]
      @yaml[:events][0][:targets].should == [:published]
    end

    it "should have state requirements" do
      @yaml[:states][0][:requirements].should == [:working_title]
    end
    it "should have event requirements" do
      @yaml[:events][0][:requirements].should == [:title]
    end    
    it "should have state hooks" do
      @yaml[:states][0][:hooks].should == {:exit=>[:bump_version]}
    end
    it "should have event hooks" do
      @yaml[:events][0][:hooks].should == {:execute=>[:generate_publicity]}
    end
   
    it "should have helpers"
    it "should have tools"

    it "should have requirement_messages" do
      @yaml[:requirement_messages][:title].should == "It needs a title"
    end
    
    it "should have arbitrary options for states" do
      @yaml[:states][0][:options].should == {:meta => {:isbn=>"snoo-factory"}}
    end
        
    it "should have arbitrary options for events" do
      @yaml[:events][0][:options].should == {:meta => :wibble}
    end
     
    it "should have options" do
      @yaml[:options].should == {:field_name=>:state_fu_field, :define_methods=>true}
    end
    
    it "raise TypeError if it is not serializable?" do
      other_machine = StateFu::Machine.new do
        named_proc(:do_stuff) { puts "I has a proc" }
      end
      lambda do
        other_machine.to_yaml
      end.should raise_error(TypeError)
    end    
  end
  
  describe "StateFu::Machine.load_yaml" do
    before do
      @loaded = StateFu::Machine.load_yaml(@machine.to_yaml)
    end
    
    it "should return a machine" do
      @loaded.should be_kind_of(StateFu::Machine)
    end
    
    it "should have states with the same names" do
      @loaded.states.names.should == @machine.states.names
    end

    it "should have events with the same names" do
      @loaded.events.names.should == @machine.events.names
    end
   
    it "should have event hooks" do
      @loaded.events.first.hooks.should == {:before=>[], :after=>[], :execute=>[:generate_publicity]}
    end
    
    it "should have state hooks" do
      @loaded.states.first.hooks.should == {:exit=>[:bump_version], :entry=>[], :accepted=>[]}
    end
    
    it "should return the same yaml if serialized again" do
      YAML.load(@loaded.to_yaml).should == YAML.load(@machine.to_yaml)
    end    
  end
  
end