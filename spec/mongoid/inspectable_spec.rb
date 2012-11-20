require "spec_helper"

describe Mongoid::Inspectable do

  describe "#inspect" do

    context "when not allowing dynamic fields" do

      let(:person) do
        Person.new(title: "CEO")
      end

      let(:inspected) do
        person.inspect
      end

      it "includes the model type" do
        expect(inspected).to include("#<Person")
      end

      it "displays the id" do
        expect(inspected).to include("_id: #{person.id}")
      end

      it "displays defined fields" do
        expect(inspected).to include("title: \"CEO\"")
      end

      it "displays field aliases" do
        expect(inspected).to include("t(test):")
      end
    end

    context "when allowing dynamic fields" do

      let(:person) do
        Person.new(title: "CEO", some_attribute: "foo")
      end

      let(:inspected) do
        person.inspect
      end

      it "includes dynamic attributes" do
        expect(inspected).to include("some_attribute: \"foo\"")
      end
    end
  end
end
