require "spec_helper"

describe Mongoid::Copyable do

  describe "#clone" do

    let(:person) do
      Person.new(:title => "Sir")
    end

    before do
      person.new_record = false
      person.addresses << Address.new(:street => "Bond")
    end

    context "when versions exist" do

      let(:cloned) do
        person.clone
      end

      before do
        person[:versions] = [ { :number => 1 } ]
      end

      it "returns a new document" do
        cloned.should_not be_persisted
      end

      it "has an id" do
        cloned.id.should_not be_nil
      end

      it "has a different id from the original" do
        cloned.id.should_not == person.id
      end

      it "does not clone the versions" do
        cloned[:versions].should be_nil
      end

      it "unmemoizes the relations" do
        cloned.addresses.should_not be_eql(person.addresses)
      end

      it "returns a new instance" do
        cloned.should_not be_eql(person)
      end

      Mongoid::Copyable::COPYABLES.each do |name|

        it "dups #{name}" do
          cloned.instance_variable_get(name).should_not
            be_eql(person.instance_variable_get(name))
        end
      end
    end
  end

  describe "#dup" do

    let(:person) do
      Person.new(:title => "Sir")
    end

    before do
      person.new_record = false
      person.addresses << Address.new(:street => "Bond")
    end

    context "when versions exist" do

      let(:duped) do
        person.dup
      end

      before do
        person[:versions] = [ { :number => 1 } ]
      end

      it "returns a new document" do
        duped.should_not be_persisted
      end

      it "has an id" do
        duped.id.should_not be_nil
      end

      it "has a different id from the original" do
        duped.id.should_not == person.id
      end

      it "does not clone the versions" do
        duped[:versions].should be_nil
      end

      it "unmemoizes the relations" do
        duped.addresses.should_not be_eql(person.addresses)
      end

      it "returns a new instance" do
        duped.should_not be_eql(person)
      end

      Mongoid::Copyable::COPYABLES.each do |name|

        it "dups #{name}" do
          duped.instance_variable_get(name).should_not
            be_eql(person.instance_variable_get(name))
        end
      end
    end
  end
end
