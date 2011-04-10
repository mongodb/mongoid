require "spec_helper"

describe Mongoid::Field do

  context "when reading the field from an oject" do

    context "when the field is a date" do

      let(:person) do
        Person.new(:dob => Date.new(1976, 11, 19))
      end

      it "returns a date object" do
        person.dob.should be_a(Date)
      end
    end
  end
end
