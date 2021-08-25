# frozen_string_literal: true

require "spec_helper"

describe "Polymorphic Associations" do

  describe "#polymorph" do

    let(:klass) do
      Class.new.tap { |c| c.send(:include, Mongoid::Document) }
    end

    context "when the relation is polymorphic" do

      context "when the relation stores a foreign key" do

        let!(:association) do
          klass.belongs_to :ratable, polymorphic: true
        end

        it "sets polymorphic to true" do
          expect(klass).to be_polymorphic
        end

        it "adds the foreign key type field" do
          expect(klass.fields["ratable_type"]).to_not be_nil
        end
      end

      context "when the relation does not store a foreign key" do

        let!(:association) do
          klass.has_many :ratings, as: :ratable
        end

        it "sets polymorphic to true" do
          expect(klass).to be_polymorphic
        end

        it "does not add the foreign key type field" do
          expect(klass.fields["ratable_type"]).to be_nil
        end

        it "does not add the foreign key inverse field field" do
          expect(klass.fields["ratable_field"]).to be_nil
        end
      end
    end

    context "when the relation is not polymorphic" do

      let!(:association) do
        klass.has_many :ratings
      end

      it "sets polymorphic to false" do
        expect(klass).to_not be_polymorphic
      end

      it "does not add the foreign key type field" do
        expect(klass.fields["ratable_type"]).to be_nil
      end

      it "does not add the foreign key inverse field field" do
        expect(klass.fields["ratable_field"]).to be_nil
      end
    end
  end

  describe ".polymorphic?" do

    context "when the document is in a polymorphic relation" do

      it "returns true" do
        expect(Movie).to be_polymorphic
      end
    end

    context "when the document is not in a polymorphic relation" do

      it "returns false" do
        expect(Survey).to_not be_polymorphic
      end
    end
  end

  describe "#polymorphic?" do

    context "when the document is in a polymorphic relation" do

      it "returns true" do
        expect(Movie.new).to be_polymorphic
      end
    end

    context "when the document is not in a polymorphic relation" do

      it "returns false" do
        expect(Survey.new).to_not be_polymorphic
      end
    end
  end

  context 'when the relation is touchable' do

    context 'when the relation is embedded' do

      let(:define_classes) do

        class FirstOwner
          include Mongoid::Document

          embeds_one :owned, class_name: 'Owned', as: :embedded_relation_polymorphic_touch_owner
        end

        class SecondOwner
          include Mongoid::Document

          embeds_one :owned, class_name: 'Owned', as: :embedded_relation_polymorphic_touch_owner
        end

        class Owned
          include Mongoid::Document

          embedded_in :embedded_relation_polymorphic_touch_owner, polymorphic: true, touch: true
        end
      end

      it 'successfully defines the touch method' do
       expect { define_classes }.not_to raise_error
      end
    end

    context 'when the relation is not embedded' do

      let(:define_classes) do

        class FirstOwner
          include Mongoid::Document

          has_one :owned, class_name: 'Owned', as: :belongs_relation_polymorphic_touch_owner
        end

        class SecondOwner
          include Mongoid::Document

          has_one :owned, class_name: 'Owned', as: :belongs_relation_polymorphic_touch_owner
        end

        class Owned
          include Mongoid::Document

          belongs_to :belongs_relation_polymorphic_touch_owner, polymorphic: true, touch: true
        end
      end

      it 'successfully defines the touch method' do
       expect { define_classes }.not_to raise_error
      end
    end
  end
end
