require "spec_helper"

describe Mongoid::Criterion::Creational do

  describe "#create" do

    context "when provided a valid selector" do

      let(:criteria) do
        Mongoid::Criteria.new(Person, false).where(:title => "Sir")
      end

      before do
        Person.expects(:create).with(:title => "Sir")
      end

      it "calls create on the class with the attributes" do
        criteria.create
      end
    end

    context "when provided invalid selectors" do

      let(:criteria) do
        Mongoid::Criteria.new(Person, false).where(:score.gt => 5)
      end

      before do
        Person.expects(:create).with({})
      end

      it "ignores the attributes" do
        criteria.create
      end
    end
  end
end
