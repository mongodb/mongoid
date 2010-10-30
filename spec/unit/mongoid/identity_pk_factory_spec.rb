require 'spec_helper'

describe Mongoid::Identity do
  context "when a PK factory exists" do
    before do
      module TestPkFactory
        def self.create_pk(row)
          row[:_id] ||= "pk_factory"
          return row
        end
      end

      Person.identity :type => String
      Mongoid.master.pk_factory = TestPkFactory
      @person = Person.allocate
    end

    after do
      Person.identity {} # reset
      Mongoid.master.instance_variable_set(:@pk_factory, nil)
    end

    context "and the id is blank" do
      before do
        @person.instance_variable_set(:@attributes, {})
        Mongoid::Identity.new(@person).create
      end

      it "should create a new id" do
        @person.id.should == "pk_factory"
      end
    end

    context "and the id exists" do
      before do
        @person.instance_variable_set(:@attributes, {:_id => "old_id"})
        Mongoid::Identity.new(@person).create
      end

      it "should return the existing id" do
        @person.id.should == "old_id"
      end
    end
  end
end
