require File.join(File.dirname(__FILE__), "/../spec_helper.rb")

describe Mongoloid do
  
  describe "#connection" do
    
    context "when connection does not exist" do
      
      before do
        @connection = mock
      end
      
      after do
        Mongoloid.connection = nil
      end
      
      it "creates a new driver" do
        XGen::Mongo::Driver::Mongo.expects(:new).returns(@connection)
        connection = Mongoloid.connection
        connection.should == @connection
      end
      
    end
    
    context "when connection already exists" do
      
      before do
        @connection = mock
        XGen::Mongo::Driver::Mongo.expects(:new).returns(@connection)
        Mongoloid.connection
      end
      
      after do
        Mongoloid.connection = nil
      end
      
      it "returns the current driver" do
        connection = Mongoloid.connection
        connection.should == @connection
      end
      
    end
    
  end
  
end