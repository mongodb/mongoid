# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Association::Constrainable do

  describe "#convert_to_foreign_key" do

    context "when the id's class stores object ids" do

      before(:all) do
        Person.field(
          :_id,
          type: BSON::ObjectId,
          pre_processed: true,
          default: ->{ BSON::ObjectId.new },
          overwrite: true
        )
      end

      let(:constrainable) do
        Post.belongs_to :person
      end

      context "when provided an object id" do

        let(:object) do
          BSON::ObjectId.new
        end

        it "returns the object id" do
          expect(constrainable.convert_to_foreign_key(object)).to eq(object)
        end
      end

      context "when provided a string" do

        let(:object) do
          BSON::ObjectId.new
        end

        it "returns an object id from the string" do
          expect(constrainable.convert_to_foreign_key(object.to_s)).to eq(object)
        end
      end
    end

    context "when the id's class does not store object ids" do

      let(:constrainable) do
        Alert.belongs_to :account
      end

      it "returns the object" do
        expect(constrainable.convert_to_foreign_key("testing")).to eq("testing")
      end
    end

    context 'when the association is polymorphic' do

      let(:constrainable) do
        Post.relations['posteable']
      end

      let(:result) do
        constrainable.convert_to_foreign_key(object)
      end

      context 'when a BSON::ObjectId is passed' do

        let(:object) do
          BSON::ObjectId.new
        end

        it 'returns the object id' do
          expect(result).to eq(object)
        end
      end

      context 'when a string is passed' do

        context 'when the string represents an ObjectId' do

          let(:object) do
            BSON::ObjectId.new.to_s
          end

          it 'returns the object id' do
            expect(result).to eq(BSON::ObjectId.from_string(object))
          end
        end

        context 'when the string does not represent an ObjectId' do

          let(:object) do
            'some-other-string'
          end

          it 'returns the object' do
            expect(result).to eq(object)
          end
        end
      end

      context 'when a model object is passed' do

        let(:object) do
          Post.new
        end

        it 'returns the id' do
          expect(result).to eq(object.id)
        end
      end
    end
  end
end
