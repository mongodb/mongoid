require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

describe Mongoid::Timestamps do

  describe "#included" do

    before do
      @person = Person.new
    end

    it "adds created_at and modified_at to the document" do
      fields = Person.instance_variable_get(:@fields)
      fields[:created_at].should_not be_nil
      fields[:modified_at].should_not be_nil
    end

  end

end
