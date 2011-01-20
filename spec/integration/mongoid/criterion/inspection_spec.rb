require "spec_helper"

describe Mongoid::Criterion::Inspection do

  before do
    Person.delete_all
  end

  describe "#inspect" do

    context "when documents match in the database" do

      let(:criteria) do
        Person.where(:age.gt => 10, :title => "Sir").limit(1)
      end

      let!(:person) do
        Person.create(:age => 20, :title => "Sir")
      end

      let(:inspection) do
        "#<Mongoid::Criteria\n" <<
        "  selector: {:age=>{\"$gt\"=>10}, :title=>\"Sir\"},\n" <<
        "  options:  {:limit=>1}>\n"
      end

      it "returns the selector, options, and empty array" do
        criteria.inspect.should == inspection
      end
    end

    context "when no documents match in the database" do

      let(:criteria) do
        Person.where(:age.gt => 10, :title => "Sir")
      end

      let(:inspection) do
        "#<Mongoid::Criteria\n" <<
        "  selector: {:age=>{\"$gt\"=>10}, :title=>\"Sir\"},\n" <<
        "  options:  {}>\n"
      end

      it "returns the selector, options, and empty array" do
        criteria.inspect.should == inspection
      end
    end
  end
end
