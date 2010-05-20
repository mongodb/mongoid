require "spec_helper"

describe Mongoid::Associations::ForeignKey do

  describe ".constraint" do

    context "when foreign key option provided" do

      it "returns the key" do
        Person.constraint(
          :post,
          { :foreign_key => :user_id },
          :in
        ).should == "user_id"
      end
    end

    context "for a references_one" do

      context "when the class is one word" do

        it "returns the class name plus _id" do
          Person.constraint(
            :post,
            {},
            :one
          ).should == "person_id"
        end
      end

      context "when the class is multiple words" do

        it "returns the underscored class name plus _id" do
          MixedDrink.constraint(
            :post,
            {},
            :one
          ).should == "mixed_drink_id"
        end
      end
    end

    context "for a references_many" do

      context "when the class is one word" do

        it "returns the class name plus _id" do
          Person.constraint(
            :posts,
            {},
            :many
          ).should == "person_id"
        end
      end

      context "when the class is multiple words" do

        it "returns the underscored class name plus _id" do
          MixedDrink.constraint(
            :posts,
            {},
            :many
          ).should == "mixed_drink_id"
        end
      end
    end

    context "for a references_many_as_array" do

      it "returns the singularized association name plus _ids" do
          Person.constraint(
            :posts,
            {},
            :many_as_array
          ).should == "post_ids"
      end
    end

    context "for a referenced_in" do

      it "returns the name plus _id" do
          Post.constraint(
            :person,
            {},
            :in
          ).should == "person_id"
      end
    end
  end
end
