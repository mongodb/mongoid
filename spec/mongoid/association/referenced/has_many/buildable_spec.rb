# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Association::Referenced::HasMany::Buildable do

  let(:base) do
    double
  end

  describe "#build" do

    let(:documents) do
      association.build(base, object)
    end

    let(:options) do
      {}
    end

    let(:association) do
      Mongoid::Association::Referenced::HasMany.new(Person, :posts, options)
    end

    context "when provided an id" do

      let(:object) do
        BSON::ObjectId.new
      end

      let(:criteria) do
        Post.where(association.foreign_key => object)
      end

      it "returns the criteria" do
        expect(documents).to eq(criteria)
      end
    end

    context "when order is specified" do

      let(:options) do
        {
          order: :rating.asc,
        }
      end

      let(:object) do
        BSON::ObjectId.new
      end

      let(:criteria) do
        Post.where(association.foreign_key => object).order_by(options[:order])
      end

      it "adds the ordering to the criteria" do
        expect(documents).to eq(criteria)
      end
    end

    context "when scope is specified" do

      let(:options) do
        {
          scope: -> { where(rating: 3) },
        }
      end

      let(:object) do
        BSON::ObjectId.new
      end

      let(:criteria) do
        Post.where(association.foreign_key => object, rating: 3)
      end

      it "adds the ordering to the criteria" do
        expect(documents).to eq(criteria)
      end
    end

    context "when the relation is polymorphic" do

      let(:options) do
        {
          as: :ratable
        }
      end

      let(:object) do
        BSON::ObjectId.new
      end

      let(:base) do
        Rating.new
      end

      let(:criteria) do
        Post.where(association.foreign_key => object, 'ratable_type' => 'Rating')
      end

      it "adds the type to the criteria" do
        expect(documents).to eq(criteria)
      end
    end

    context "when provided a object" do

      let(:object) do
        [ Person.new ]
      end

      it "returns the object" do
        expect(documents).to eq(object)
      end
    end

    context "when no documents found in the database" do

      context "when the ids are empty" do

        let(:object) do
          [ nil ]
        end

        it "returns an empty array" do
          expect(documents).to be_empty
        end

        context "during initialization" do

          it "returns an empty array" do
            Person.new do |p|
              expect(p.posts).to be_empty
              expect(p.posts._association).to_not be_nil
            end
          end
        end
      end
    end

    context 'when the object is already associated with another object' do

      context "when using <<" do

        let(:person1) do
          Person.new
        end

        let(:person2) do
          Person.new
        end

        let(:drug) do
          Drug.new
        end

        before do
          person1.drugs << drug
          person2.drugs << drug
        end

        it 'clears the object of its previous association' do
          expect(person1.drugs).to eq([])
          expect(person1.drug_ids).to eq([])
          expect(person2.drugs).to eq([drug])
          expect(person2.drug_ids).to eq([drug._id])
        end
      end

      context "when using concat" do

        let(:person1) do
          Person.new
        end

        let(:person2) do
          Person.new
        end

        let(:drug) do
          Drug.new
        end

        before do
          person1.drugs.concat([drug])
          person2.drugs.concat([drug])
        end

        it 'clears the object of its previous association' do
          expect(person1.drugs).to eq([])
          expect(person1.drug_ids).to eq([])
          expect(person2.drugs).to eq([drug])
          expect(person2.drug_ids).to eq([drug._id])
        end
      end

      context "when using =" do

        let(:person1) do
          Person.new
        end

        let(:person2) do
          Person.new
        end

        let(:drug) do
          Drug.new
        end

        before do
          person1.drugs = [drug]
          person2.drugs = [drug]
        end

        it 'clears the object of its previous association' do
          expect(person1.drugs).to eq([])
          expect(person1.drug_ids).to eq([])
          expect(person2.drugs).to eq([drug])
          expect(person2.drug_ids).to eq([drug._id])
        end
      end

      context "when using = on the same document twice" do

        let(:person1) do
          Person.new
        end

        let(:person2) do
          Person.new
        end

        let(:drug) do
          Drug.new
        end

        before do
          person1.drugs = [drug]
          person1.drugs = [drug]
        end

        it 'clears the object of its previous association' do
          expect(person1.drugs).to eq([drug])
          expect(person1.drug_ids).to eq([drug._id])
        end
      end
    end
  end
end
