require "spec_helper"

describe Mongoid::Criterion::Inspection do

  describe "#inspect" do

    let(:criteria) do
      Person.where(:age.gt => 10, title: "Sir")
    end

    it "includes the selector" do
      criteria.inspect.should include("selector")
    end

    it "includes the options" do
      criteria.inspect.should include("options")
    end

    it "includes the class" do
      criteria.inspect.should include("class")
    end

    it "includes the embedded flag" do
      criteria.inspect.should include("embedded")
    end
  end
end
