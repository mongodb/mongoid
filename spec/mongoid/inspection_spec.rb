require "spec_helper"

describe Mongoid::Inspection do

  describe "#inspect" do

    context "when not allowing dynamic fields" do

      before do
        Mongoid.configure.allow_dynamic_fields = false
      end

      let(:person) do
        Person.new(title: "CEO")
      end

      let(:inspected) do
        person.inspect
      end

      it "includes the model type" do
        inspected.should include("#<Person")
      end

      it "displays the id" do
        inspected.should include("_id: #{person.id}")
      end

      it "displays defined fields" do
        inspected.should include("title: \"CEO\"")
      end

      it "displays field aliases" do
        inspected.should include("t(test):")
      end
    end

    context "when allowing dynamic fields" do

      let(:person) do
        Person.new(title: "CEO", some_attribute: "foo")
      end

      let(:inspected) do
        person.inspect
      end

      before do
        Mongoid.configure.allow_dynamic_fields = true
      end

      it "includes dynamic attributes" do
        inspected.should include("some_attribute: \"foo\"")
      end
    end
  end
end
