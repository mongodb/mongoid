require "spec_helper"

describe Mongoid::Timestamps do

  describe ".included" do

    let(:person) do
      Person.new
    end

    let(:fields) do
      Person.fields
    end

    before do
      person.run_callbacks(:create)
      person.run_callbacks(:save)
    end

    it "adds created_at to the document" do
      fields["created_at"].should_not be_nil
    end

    it "adds updated_at to the document" do
      fields["updated_at"].should_not be_nil
    end

    it "forces the created_at timestamps to UTC" do
      person.created_at.should be_within(10).of(Time.now.utc)
    end

    it "forces the updated_at timestamps to UTC" do
      person.updated_at.should be_within(10).of(Time.now.utc)
    end

    it "includes a record_timestamps class_accessor to ease AR compatibility" do
      Person.should.respond_to? :record_timestamps
    end
  end

  context "when the document has not changed" do

    let(:person) do
      Person.instantiate(:created_at => Time.now.utc)
    end

    before do
      person.new_record = false
    end

    it "does not run the update callbacks" do
      person.expects(:updated_at=).never
      person.save
    end
  end

  context "when the document has changed with updated_at specified" do

    let(:person) do
      Person.new(:created_at => Time.now.utc)
    end

    before do
      person.new_record = false
    end

    it "does not set updated at" do
      person.updated_at = DateTime.parse("2001-06-12")
      person.expects(:updated_at=).never
      person.save
    end
  end

  context "when the document is created" do

    let(:person) do
      Person.create
    end

    it "runs the update callbacks" do
      person.updated_at.should_not be_nil
      person.updated_at.should be_within(10).of(Time.now.utc)
    end
  end
  
  describe "#cache_key" do
    let(:person) do
      Person.new
    end

    let(:fields) do
      Person.fields
    end
    
    context "when the document is new" do
      it "should have a new key name" do
        person.cache_key.should eq "people/new"
      end
    end
    
    context "when persisted" do
      
      before do
        person.save
      end
      
      context "with updated_at" do
        it "should have the id and updated_at key name" do
          updated_at = person.updated_at.utc.to_s(:number)
          person.cache_key.should eq "people/#{person.id}-#{updated_at}"
        end
      end

      context "without updated_at" do
        it "should have the id key name" do        
          person.updated_at = nil
          person.cache_key.should eq "people/#{person.id}"
        end
      end
      
      
    end
    
    
  end
  
end
