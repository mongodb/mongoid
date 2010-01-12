require "spec_helper"

describe Mongoid::NamedScope do

  describe ".named_scope" do

    class Person
      named_scope :doctors, {:where => {:title => 'Dr.'} }
      named_scope :old, criteria.where(:age.gt => 50)
    end

    before do
      @document = Person.create(:title => "Dr.", :age => 65, :terms => true)
    end

    after do
      Person.delete_all
    end

    context "accessing a single named scope" do

      it "returns the document" do
        Person.doctors.first.should == @document
      end

    end

    context "chaining named scopes" do

      it "returns the document" do
        Person.old.doctors.first.should == @document
      end

    end

    context "mixing named scopes and class methods" do

      it "returns the document" do
        Person.accepted.old.doctors.first.should == @document
      end

    end

  end

end
