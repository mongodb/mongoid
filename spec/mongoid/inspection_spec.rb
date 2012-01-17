require "spec_helper"

describe Mongoid::Inspection do

  describe "#inspect" do

    context "when not allowing dynamic fields" do

      before do
        Mongoid.configure.allow_dynamic_fields = false
      end

      let(:person) do
        Person.new(:title => "CEO")
      end

      let(:attributes) do
        Person.fields.map do |name, field|
          unless name == "_id"
            "#{name}: #{person.attributes[name].nil? ? "nil" : person.attributes[name].inspect}"
          end
        end.compact * ", "
      end

      it "returns a string of class name and attributes" do
        person.inspect.should == "#<Person _id: #{person.id}, #{attributes}>"
      end
    end

    context "when allowing dynamic fields" do

      let(:person) do
        Person.new(:title => "CEO", :some_attribute => "foo")
      end

      let(:attributes) do
        Person.fields.map do |name, field|
          unless name == "_id"
            "#{name}: #{person.attributes[name].nil? ? "nil" : person.attributes[name].inspect}"
          end
        end.compact * ", "
      end

      before do
        Mongoid.configure.allow_dynamic_fields = true
        attributes << ", some_attribute: #{person.attributes['some_attribute'].inspect}"
      end

      it "returns a string of class name, attributes, and dynamic attributes" do
        person.inspect.should == "#<Person _id: #{person.id}, #{attributes}>"
      end
    end
  end
end
