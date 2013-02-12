# -*- coding: utf-8 -*-
require "spec_helper"

describe Mongoid::Equality do

  let(:klass) do
    Person
  end

  let(:person) do
    Person.new
  end

  describe "#==" do

    context "when comparable is not a document" do

      let(:other) do
        "Document"
      end

      it "returns false" do
        person.should_not eq(other)
      end
    end

    context "when comparable is a document" do

      context "when it has the same id" do

        context "when the classes are not the same" do

          let(:other) do
            Post.new
          end

          before do
            other.id = person.id
          end

          it "returns false" do
            person.should_not eq(other)
          end
        end

        context "when the classes are the same" do

          let(:other) do
            Person.new
          end

          before do
            other.id = person.id
          end

          it "returns true" do
            person.should eq(other)
          end
        end
      end

      context "when it has a different id" do

        let(:other) do
          Person.new
        end

        context "when the instances are the same" do

          it "returns true" do
            person.should eq(person)
          end
        end

        context "when the instances are different" do

          it "returns false" do
            person.should_not eq(other)
          end
        end
      end
    end
  end

  describe ".===" do

    context "when comparable is an instance of this document" do

      it "returns true" do
        (klass === person).should be_true
      end
    end

    context "when comparable is a relation of this document" do

      let(:relation) do
        Post.new(person: person).person
      end

      it "returns true" do
        (klass === relation).should be_true
      end
    end

    context "when comparable is the same class" do

      it "returns true" do
        (klass === Person).should be_true
      end
    end

    context "when the comparable is a subclass" do

      it "returns false" do
        (Person === Doctor).should be_false
      end
    end

    context "when the comparable is an instance of a subclass" do

      it "returns true" do
        (Person === Doctor.new).should be_true
      end
    end
  end

  describe "#===" do

    context "when comparable is the same type" do

      context "when the instance is different" do

        it "returns false" do
          (person === Person.new).should be_false
        end
      end

      context "when the instance is the same" do

        it "returns true" do
          (person === person).should be_true
        end
      end
    end

    context "when the comparable is a subclass" do

      it "returns false" do
        (person === Doctor.new).should be_false
      end
    end

    context "when comparing to a class" do

      context "when the class is the same" do

        it "returns true" do
          (person === Person).should be_true
        end
      end

      context "when the class is a subclass" do

        it "returns false" do
          (person === Doctor).should be_false
        end
      end

      context "when the class is a superclass" do

        it "returns true" do
          (Doctor.new === Person).should be_true
        end
      end
    end
  end

  describe "#<=>" do

    let(:first) do
      Person.new
    end

    let(:second) do
      Person.new
    end

    it "compares based on the document id" do
      (first <=> second ).should eq(-1)
    end
  end

  describe "#eql?" do

    context "when comparable is not a document" do

      let(:other) do
        "Document"
      end

      it "returns false" do
        person.should_not be_eql(other)
      end
    end

    context "when comparable is a document" do

      let(:other) do
        Person.new
      end

      context "when it has the same id" do

        before do
          other.id = person.id
        end

        it "returns true" do
          person.should be_eql(other)
        end
      end

      context "when it has a different id" do

        context "when the instances are the same" do

          it "returns true" do
            person.should be_eql(person)
          end
        end

        context "when the instances are different" do

          it "returns false" do
            person.should_not be_eql(other)
          end
        end
      end
    end
  end
end