require "spec_helper"

describe Mongoid::Timestamps do

  describe ".included" do

    before do
      @person = Person.new
    end

    it "adds created_at and updated_at to the document" do
      fields = Person.fields
      fields["created_at"].should_not be_nil
      fields["updated_at"].should_not be_nil
    end

    it "forces the timestamps to UTC" do
      @person.run_callbacks(:create)
      @person.run_callbacks(:save)
      @person.created_at.should be_close(Time.now.utc, 10.seconds)
      @person.updated_at.should be_close(Time.now.utc, 10.seconds)
    end
    
    it "includes a record_timestamps class_accessor to ease AR compatibility" do
      Person.should.respond_to? :record_timestamps
    end
    
    context 'record_timestamps is set to false' do
      before :all do
        Person.record_timestamps = false
      end
      
      it 'does not update updated_at' do
        person = Person.new
        person.run_callbacks(:save)
        updated_at_before = person.updated_at
        sleep(1)
        person.run_callbacks(:save)
        person.updated_at.should == updated_at_before
      end
      
      it 'does not add created_at' do
        person = Person.new
        person.run_callbacks(:create)
        person.created_at.should == nil
      end
    end

  end

end
