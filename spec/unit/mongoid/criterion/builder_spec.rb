require "spec_helper"

describe Mongoid::Criterion::Builder do

  describe "#build" do

    context "when provided a valid selector" do

      let(:criteria) do
        Mongoid::Criteria.new(Person, false).where(:title => "Sir")
      end

      before do
        Person.expects(:new).with(:title => "Sir")
      end

      it "calls create on the class with the attributes" do
        criteria.build
      end
    end

    context "when provided invalid selectors" do

      let(:criteria) do
        Mongoid::Criteria.new(Person, false).where(:score.gt => 5)
      end

      before do
        Person.expects(:new).with({})
      end

      it "ignores the attributes" do
        criteria.build
      end
    end

    context "with attributes" do
      let(:criteria) do
        Mongoid::Criteria.new(Person, false).where(:title => "Sir")
      end

      before do
        Person.expects(:new).with(:title => "Sir", :name => "Lancelot")
      end

      it "calls create on the class with the attributes" do
        criteria.build(:name => "Lancelot")
      end
    end

  end
end
