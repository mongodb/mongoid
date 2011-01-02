require "spec_helper"

describe Mongoid::Contexts::Mongo do

  before do
    Person.delete_all
  end

  describe "#avg" do

    context "when no documents are in the collection" do

      it "returns nil" do
        Person.avg(:age).should == nil
      end
    end

    context "when documents exist in the collection" do

      before do
        5.times do |n|
          Person.create(
            :title => "Sir",
            :age => ((n + 1) * 10),
            :aliases => ["D", "Durran"],
            :ssn => "#{n}"
          )
        end
      end

      it "returns the average for the field" do
        Person.avg(:age).should == 30
      end
    end
  end

  describe "#max" do

    context "when no documents are in the collection" do

      it "returns nil" do
        Person.max(:age).should == nil
      end
    end

    context "when documents are in the collection" do

      before do
        5.times do |n|
          Person.create(
            :title => "Sir",
            :age => (n * 10),
            :aliases => ["D", "Durran"],
            :ssn => "#{n}"
          )
        end
      end

      it "returns the maximum for the field" do
        Person.max(:age).should == 40
      end
    end
  end

  describe "#min" do

    context "when no documents are in the collection" do

      it "returns nil" do
        Person.min(:age).should == nil
      end
    end

    context "when documents are in the collection" do

      before do
        5.times do |n|
          Person.create(
            :title => "Sir",
            :age => ((n + 1) * 10),
            :aliases => ["D", "Durran"],
            :ssn => "#{n}"
          )
        end
      end

      it "returns the minimum for the field" do
        Person.min(:age).should == 10.0
      end
    end
  end

  describe "#sum" do

    context "when no documents are in the collection" do

      it "returns nil" do
        Person.sum(:age).should == nil
      end
    end

    context "when documents are in the collection" do

      before do
        5.times do |n|
          Person.create(
            :title => "Sir",
            :age => 5,
            :aliases => ["D", "Durran"],
            :ssn => "#{n}"
          )
        end
      end

      it "returns the sum for the field" do
        Person.where(:age.gt => 3).sum(:age).should == 25
      end
    end
  end
end
