require "spec_helper"

describe Mongoid::MultiDatabase do
  let(:klass) do
    Class.new do
      include Mongoid::Document
    end
  end

  describe ".database" do
    before do
      klass.set_database :secondary
    end

    it "sets the database key on the class" do
      klass.database.should eq("secondary")
    end
  end

  describe ".inherited" do
    let(:child) do
      Class.new do
        include Mongoid::Document
      end
    end

    context "when database" do

      before do
        klass.set_database("secondary")
        klass.inherited(child)
      end

      it "sets the parents database" do
        child.database.should eq("secondary")
      end
    end

    context "when no database" do
      before do
        klass.inherited(child)
      end

      it "does nothing" do
        child.database.should be_nil
      end
    end
  end
end
