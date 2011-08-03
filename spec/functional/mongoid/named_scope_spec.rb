require "spec_helper"

describe Mongoid::NamedScope do

  describe ".scope" do

    before(:all) do
      Person.class_eval do
        scope :doctors, {:where => {:title => 'Dr.'} }
        scope :old, criteria.where(:age.gt => 50)
        scope :alki, where(:blood_alcohol_content.gt => 0.3).order_by(:blood_alcohol_content.asc)
      end
    end

    let!(:document) do
      Person.create(
        :title => "Dr.",
        :age => 65,
        :terms => true,
        :ssn => "123-22-8346"
      )
    end

    after do
      Person.delete_all
    end

    context "when accessing an any_of scope first" do

      let(:criteria) do
        Person.search("Dr.").old
      end

      it "returns the correct results" do
        criteria.should eq([ document ])
      end
    end

    context "accessing a single named scope" do

      it "returns the document" do
        Person.doctors.first.should == document
      end
    end

    context "chaining named scopes" do

      it "returns the document" do
        Person.old.doctors.first.should == document
      end
    end

    context "mixing named scopes and class methods" do

      it "returns the document" do
        Person.accepted.old.doctors.first.should == document
      end
    end

    context "using order_by in a named scope" do

      before do
        Person.create(:blood_alcohol_content => 0.5, :ssn => "121-22-8346")
        Person.create(:blood_alcohol_content => 0.4, :ssn => "124-22-8346")
        Person.create(:blood_alcohol_content => 0.7, :ssn => "125-22-8346")
      end

      it "sorts the results" do
        docs = Person.alki
        docs.first.blood_alcohol_content.should == 0.4
      end
    end

    context "when an class attribute is defined" do

      it "should be accessible" do
        Person.somebody_elses_important_class_options.should == { :keep_me_around => true }
      end

    end

    context "when calling scopes on parent classes" do

      it "inherits the scope" do
        Doctor.minor.should == []
      end

      it "inherits the class attribute methods" do
        Doctor.somebody_elses_important_class_options.should == { :keep_me_around => true }
      end

    end
  end
end
