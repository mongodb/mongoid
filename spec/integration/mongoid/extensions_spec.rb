require "spec_helper"

describe Mongoid::Extensions do

  context "setting floating point numbers" do

    context "when value is an empty string" do

      let(:person) { Person.new(:ssn => "555555555555555") }

      before do
        Person.validates_numericality_of :blood_alcohol_content, :allow_blank => true
      end

      it "does not set the value" do
        person.save.should be_true
      end

    end
  end

  context "setting association foreign keys" do

    context "when value is a string" do
      

      before do
        @game = Game.new
        @person = Person.create(:ssn => "555555555555555")
      end

      it "should set the foreign key as ObjectID" do
        @game.person_id = @person.id.to_s
        @game.save
        @game.reload.person_id.should == @person.id
      end

    end
    
    context "when value is a ObjectID" do

      before do
        @game = Game.new
        @person = Person.create(:ssn => "555555555555555")
      end

      it "should keep the the foreign key as ObjectID" do
        @game.person_id = @person.id
        @game.save
        @game.reload.person_id.should == @person.id
      end

    end
    
  end

end
