# frozen_string_literal: true

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
        expect(inspected).to include(%q,title: "CEO",)
      end

      it "displays field aliases" do
        expect(inspected).to include("t(test):")
      end

      it "displays the default discriminator key" do
        expect(inspected).to include(%q,_type: "Person",)
      end
    end

    context "when using a custom discriminator key" do

      before do
        Person.discriminator_key = "dkey"
      end

      after do
        Person.discriminator_key = nil
      end

      let(:person) do
        Person.new(title: "CEO")
      end

      let(:inspected) do
        person.inspect
      end

      it "displays the new discriminator key" do
        expect(inspected).to include(%q,dkey: "Person",)
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
        expect(inspected).to include(%q,some_attribute: "foo",)
      end
    end

    context 'when id is unaliased' do
      let(:shirt) { Shirt.new(id: 1, _id: 2) }

      it 'shows the correct _id and id values' do
        shirt.inspect.should == "#<Shirt _id: 2, color: nil, id: \"1\">"
      end
    end
  end
end
