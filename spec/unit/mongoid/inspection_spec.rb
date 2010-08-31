require "spec_helper"

describe Mongoid::Inspection do

  describe "#inspect" do

    context "with allow_dynamic_fields = false" do
      before do
        Mongoid.configure.allow_dynamic_fields = false
        @person = Person.new :title => "CEO"
      end

      it "returns a pretty string of class name and attributes" do
        attrs = Person.fields.map do |name, field|
          "#{name}: #{@person.attributes[name].nil? ? "nil" : @person.attributes[name].inspect}"
        end * ", "
        @person.inspect.should == "#<Person _id: #{@person.id}, #{attrs}>"
      end
    end

    context "with allow_dynamic_fields = true" do
      before do
        Mongoid.configure.allow_dynamic_fields = true
        @person = Person.new(:title => "CEO", :some_attribute => "foo")
        @person.addresses << Address.new(:street => "test")
      end

      it "returns a pretty string of class name, attributes, and dynamic attributes" do
        attrs = Person.fields.map do |name, field|
          "#{name}: #{@person.attributes[name].nil? ? "nil" : @person.attributes[name].inspect}"
        end * ", "
        attrs << ", some_attribute: #{@person.attributes['some_attribute'].inspect}"
        @person.inspect.should == "#<Person _id: #{@person.id}, #{attrs}>"
      end
    end
  end
end
