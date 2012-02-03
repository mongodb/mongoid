require "spec_helper"

describe Mongoid::Criterion::Inspection do

  describe "#inspect" do

    pending "when documents match in the database" do

      let(:criteria) do
        Person.where(:age.gt => 10, title: "Sir")
      end

      let!(:person) do
        Person.create(age: 20, title: "Sir")
      end

      let(:inspection) do
        "#<Mongoid::Criteria\n" <<
        "  selector: {:age=>{\"$gt\"=>10}, :title=>\"Sir\"},\n" <<
        "  options:  {},\n" <<
        "  class:    Person,\n" <<
        "  embedded: false>\n"
      end

      it "returns the selector, options, and empty array" do
        criteria.inspect.should eq(inspection)
      end
    end

    pending "when no documents match in the database" do

      let(:criteria) do
        Person.where(:age.gt => 10, title: "Sir")
      end

      let(:inspection) do
        "#<Mongoid::Criteria\n" <<
        "  selector: {:age=>{\"$gt\"=>10}, :title=>\"Sir\"},\n" <<
        "  options:  {},\n" <<
        "  class:    Person,\n" <<
        "  embedded: false>\n"
      end

      it "returns the selector, options, and empty array" do
        criteria.inspect.should eq(inspection)
      end
    end
  end
end
