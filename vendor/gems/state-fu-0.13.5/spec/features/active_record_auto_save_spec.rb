require File.expand_path("#{File.dirname(__FILE__)}/../helper")

describe "machine(:autosave => true)" do
  before(:all) do
    reset!
    prepare_active_record() do
      def self.up
        create_table :example_records do |t|
          t.string :name,           :null => false
          t.string :state_fu_field, :null => false
          t.string :description
          t.string :status
          t.timestamps
        end
      end
    end
  end
  
  it "should automatically save the record when a transition is complete" do
    pending
  end
end