require "spec_helper"

describe Mongoid::Extensions do

  context "setting floating point numbers" do

    context "when value is an empty string" do

      let(:person) { Person.new }

      before do
        Person.validates_numericality_of :blood_alcohol_content, :allow_blank => true
      end

      after do
        Person.validations.clear
      end

      it "does not set the value" do
        person.save.should be_true
      end

    end
  end

end
