require "spec_helper"

describe Mongoid::NamedScope do

  describe ".named_scope" do

    class Person
      named_scope :doctors, {:where => {:title => 'Dr.'}}
    end

    before do
      @document = Person.create(:title => "Dr.")
    end

    after do
      Person.delete_all
    end

    it "returns the document" do
      Person.doctors.first.should == @document
    end

  end

end
