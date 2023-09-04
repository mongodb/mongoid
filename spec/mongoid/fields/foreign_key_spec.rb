# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"

describe Mongoid::Fields::ForeignKey do

  describe "#add_atomic_changes" do

    let(:field) do
      described_class.new(
        :vals,
        association: Person.relations["preferences"],
        type: Array,
        default: [],
        identity: true
      )
    end

    let(:person) do
      Person.new
    end

    let(:preference_one) do
      Preference.new
    end

    let(:preference_two) do
      Preference.new
    end

    let(:preference_three) do
      Preference.new
    end

    let(:mods) do
      {}
    end

    before do
      person.preferences.concat([ preference_one, preference_three ])
    end

    context "when adding and removing" do

      before do
        field.add_atomic_changes(
          person,
          "preference_ids",
          "preference_ids",
          mods,
          [ preference_three.id ],
          [ preference_two.id ]
        )
      end

      it "adds the current to the modifications" do
        expect(mods["preference_ids"]).to eq(
          [ preference_one.id, preference_three.id ]
        )
      end
    end
  end

  describe "#eval_default" do

    let(:default) do
      [ BSON::ObjectId.new ]
    end

    let(:field) do
      described_class.new(
        :vals,
        association: Person.relations["posts"],
        type: Array,
        default: default,
        identity: true
      )
    end

    it "dups the default value" do
      expect(field.eval_default(Person.new)).to_not equal(default)
    end

    it "returns the correct value" do
      expect(field.eval_default(Person.new)).to eq(default)
    end
  end

  describe "#foreign_key?" do

    let(:field) do
      described_class.new(
        :vals,
        association: Person.relations["posts"],
        type: Array,
        default: [],
        identity: true
      )
    end

    it "returns true" do
      expect(field).to be_foreign_key
    end
  end

  describe "#evolve" do

    let(:association) do
      Person.reflect_on_association(:preferences)
    end

    context "when provided a document" do

      let(:field) do
        described_class.new(:person_id, type: Object, association: association)
      end

      let(:game) do
        Game.new
      end

      let(:evolved) do
        field.evolve(game)
      end

      it "returns the id for the document" do
        expect(evolved).to eq(game.id)
      end
    end

    context "when the type is an array" do

      let(:field) do
        described_class.new(:preference_ids, type: Array, default: [], association: association)
      end

      context "when providing a single value" do

        context "when the value is an id string" do

          let(:id) do
            BSON::ObjectId.new
          end

          let(:evolved) do
            field.evolve(id.to_s)
          end

          it "converts the value to an object id" do
            expect(evolved).to eq(id)
          end
        end

        context "when the value is a normal string" do

          let(:evolved) do
            field.evolve("testing")
          end

          it "does not convert the value" do
            expect(evolved).to eq("testing")
          end
        end

        context "when the value is an empty string" do

          let(:evolved) do
            field.evolve("")
          end

          it "does not convert the value" do
            expect(evolved).to be_empty
          end
        end
      end

      context "when providing an array" do

        context "when the values are id strings" do

          context "when the relation stores ids as object ids" do

            let(:id_one) do
              BSON::ObjectId.new
            end

            let(:id_two) do
              BSON::ObjectId.new
            end

            let(:evolved) do
              field.evolve([ id_one.to_s, id_two.to_s ])
            end

            it "converts the value to an object id" do
              expect(evolved).to eq([ id_one, id_two ])
            end
          end

          context "when the relation stores ids as strings" do

            let!(:association) do
              Agent.reflect_on_association(:accounts)
            end

            let!(:field) do
              described_class.new(:account_ids, type: Array, default: [], association: association)
            end

            let(:id_one) do
              BSON::ObjectId.new.to_s
            end

            let(:id_two) do
              BSON::ObjectId.new.to_s
            end

            let(:evolved) do
              field.evolve([ id_one, id_two ])
            end

            it "does not convert the values to object ids" do
              expect(evolved).to eq([ id_one, id_two ])
            end
          end
        end

        context "when the values are normal strings" do

          let(:evolved) do
            field.evolve([ "testing" ])
          end

          it "does not convert the value" do
            expect(evolved).to eq([ "testing" ])
          end
        end

        context "when the values are empty strings" do

          let(:evolved) do
            field.evolve([ "" ])
          end

          it "does not convert the value" do
            expect(evolved).to eq([ "" ])
          end
        end

        context "when the values are nils" do

          let(:evolved) do
            field.evolve([ nil ])
          end

          it "does not convert the value" do
            expect(evolved).to eq([ nil ])
          end
        end
      end
    end

    context "when the type is an object" do

      let(:association) do
        Game.reflect_on_association(:person)
      end

      let(:field) do
        described_class.new(:person_id, type: Object, association: association)
      end

      context "when providing a single value" do

        context "when the relation stores object ids" do

          context "when the value is an id string" do

            let(:id) do
              BSON::ObjectId.new
            end

            let(:evolved) do
              field.evolve(id.to_s)
            end

            it "converts the value to an object id" do
              expect(evolved).to eq(id)
            end
          end

          context "when the value is a normal string" do

            let(:evolved) do
              field.evolve("testing")
            end

            it "does not convert the value" do
              expect(evolved).to eq("testing")
            end
          end

          context "when the value is an empty string" do

            let(:evolved) do
              field.evolve("")
            end

            it "does not convert the value" do
              expect(evolved).to be_empty
            end
          end
        end

        context "when the relation stores string ids" do

          let(:association) do
            Comment.reflect_on_association(:account)
          end

          let(:field) do
            described_class.new(:person_id, type: Object, association: association)
          end

          context "when the value is an id string" do

            let(:id) do
              BSON::ObjectId.new
            end

            let(:evolved) do
              field.evolve(id.to_s)
            end

            it "does not convert the value to an object id" do
              expect(evolved).to eq(id.to_s)
            end
          end

          context "when the value is a normal string" do

            let(:evolved) do
              field.evolve("testing")
            end

            it "does not convert the value" do
              expect(evolved).to eq("testing")
            end
          end

          context "when the value is an empty string" do

            let(:evolved) do
              field.evolve("")
            end

            it "does not convert the value" do
              expect(evolved).to be_empty
            end
          end
        end
      end

      context "when providing an array" do

        context "when the values are id strings" do

          context "when the relation stores ids as object ids" do

            let(:id_one) do
              BSON::ObjectId.new
            end

            let(:id_two) do
              BSON::ObjectId.new
            end

            let(:evolved) do
              field.evolve([ id_one.to_s, id_two.to_s ])
            end

            it "converts the value to an object id" do
              expect(evolved).to eq([ id_one, id_two ])
            end
          end

          context "when the relation stores ids as strings" do

            let(:association) do
              Comment.reflect_on_association(:account)
            end

            let(:field) do
              described_class.new(:person_id, type: Object, association: association)
            end

            let(:id_one) do
              BSON::ObjectId.new.to_s
            end

            let(:id_two) do
              BSON::ObjectId.new.to_s
            end

            let(:evolved) do
              field.evolve([ id_one, id_two ])
            end

            it "does not convert the values to object ids" do
              expect(evolved).to eq([ id_one, id_two ])
            end
          end
        end

        context "when the values are normal strings" do

          let(:evolved) do
            field.evolve([ "testing" ])
          end

          it "does not convert the value" do
            expect(evolved).to eq([ "testing" ])
          end
        end

        context "when the values are empty strings" do

          let(:evolved) do
            field.evolve([ "" ])
          end

          it "does not convert the value" do
            expect(evolved).to eq([ "" ])
          end
        end

        context "when the values are nils" do

          let(:evolved) do
            field.evolve([ nil ])
          end

          it "does not convert the value" do
            expect(evolved).to eq([ nil ])
          end
        end
      end
    end

    context "when the association is polymoprhic" do

      let(:association) do
        Agent.reflect_on_association(:names)
      end

      let(:field) do
        described_class.new(:nameable_id, type: Object, association: association)
      end

      let(:value) do
        BSON::ObjectId.new().to_s
      end

      let(:evolved) do
        field.evolve(value)
      end

      it "does not change the foreign key" do
        expect(evolved).to eq(BSON::ObjectId.from_string(value))
      end
    end
  end

  describe "#lazy?" do

    context "when the key is resizable" do

      let(:field) do
        described_class.new(:test, type: Array, overwrite: true)
      end

      it "returns true" do
        expect(field).to be_lazy
      end
    end

    context "when the key is not resizable" do

      let(:field) do
        described_class.new(:test, type: BSON::ObjectId, overwrite: true)
      end

      it "returns false" do
        expect(field).to_not be_lazy
      end
    end
  end

  describe '#mongoize' do
    let(:field) do
      described_class.new(
        :vals,
        type: type,
        default: [],
        identity: true,
        association: association,
        overwrite: true
      )
    end
    let(:association) { Game.relations['person'] }
    subject(:mongoized) { field.mongoize(object) }

    context 'type is Array' do
      let(:type) { Array }

      context 'when the object is a BSON::ObjectId' do
        let(:object) { BSON::ObjectId.new }

        it 'returns the object id as an array' do
          expect(mongoized).to eq([object])
        end
      end

      context 'when the object is an Array of BSON::ObjectId' do
        let(:object) { [BSON::ObjectId.new] }

        it 'returns the object ids' do
          expect(mongoized).to eq(object)
        end
      end

      context 'when the object is a String which is a legal object id' do
        let(:object) { BSON::ObjectId.new.to_s }

        it 'returns the object id in an array' do
          expect(mongoized).to eq([BSON::ObjectId.from_string(object)])
        end
      end

      context 'when the object is a String which is not a legal object id' do
        let(:object) { 'blah' }

        it 'returns the object id in an array' do
          expect(mongoized).to eq(%w[blah])
        end
      end

      context 'when the object is a blank String' do
        let(:object) { '' }

        it 'returns an empty array' do
          expect(mongoized).to eq([])
        end
      end

      context 'when the object is nil' do
        let(:object) { nil }

        it 'returns an empty array' do
          expect(mongoized).to eq([])
        end
      end

      context 'when the object is Array of Strings which are legal object ids' do
        let(:object) { [BSON::ObjectId.new.to_s] }

        it 'returns the object id in an array' do
          expect(mongoized).to eq([BSON::ObjectId.from_string(object.first)])
        end
      end

      context 'when the object is Array of Strings which are not legal object ids' do
        let(:object) { %w[blah] }

        it 'returns the Array' do
          expect(mongoized).to eq(%w[blah])
        end
      end

      context 'when the object is Array of Strings which are blank' do
        let(:object) { ['', ''] }

        it 'returns an empty Array' do
          expect(mongoized).to eq([])
        end
      end

      context 'when the object is Array of nils' do
        let(:object) { [nil, nil, nil] }

        it 'returns an empty Array' do
          expect(mongoized).to eq([])
        end
      end

      context 'when the object is an empty Array' do
        let(:object) { [] }

        it 'returns an empty Array' do
          expect(mongoized).to eq([])
        end

        it 'returns the same instance' do
          expect(mongoized).to equal(object)
        end
      end

      context 'when the object is a Set' do
        let(:object) { Set['blah'] }

        it 'returns the object id in an array' do
          expect(mongoized).to eq(%w[blah])
        end
      end

      context 'when foreign key is a String' do
        before do
          Person.field(:_id, type: String, overwrite: true)
        end

        after do
          Person.field(
            :_id,
            type: BSON::ObjectId,
            pre_processed: true,
            default: ->{ BSON::ObjectId.new },
            overwrite: true
          )
        end

        context 'when the object is a String' do
          let(:object) { %w[1] }

          it 'returns String' do
            expect(mongoized).to eq(object)
          end
        end

        context 'when the object is a BSON::ObjectId' do
          let(:object) { [BSON::ObjectId.new] }

          it 'converts to String' do
            expect(mongoized).to eq([object.first.to_s])
          end
        end

        context 'when the object is an Integer' do
          let(:object) { [1] }

          it 'converts to String' do
            expect(mongoized).to eq(%w[1])
          end
        end
      end

      context 'when foreign key is an Integer' do
        before do
          Person.field(:_id, type: Integer, overwrite: true)
        end

        after do
          Person.field(
            :_id,
            type: BSON::ObjectId,
            pre_processed: true,
            default: ->{ BSON::ObjectId.new },
            overwrite: true
          )
        end

        context 'when the object is a String' do
          let(:object) { %w[1] }

          it 'converts to Integer' do
            expect(mongoized).to eq([1])
          end
        end

        context 'when the object is an Integer' do
          let(:object) { [1] }

          it 'returns Integer' do
            expect(mongoized).to eq([1])
          end
        end
      end
    end

    context 'type is Set' do
      let(:type) { Set }

      context 'when the object is an Array of BSON::ObjectId' do
        let(:object) { [BSON::ObjectId.new] }

        it 'returns the object ids' do
          expect(mongoized).to eq(object)
        end
      end

      context 'when the object is a Set of BSON::ObjectId' do
        let(:object) { Set[BSON::ObjectId.new] }

        it 'returns the object id in an array' do
          expect(mongoized).to eq([object.first])
        end
      end
    end

    context 'type is Object' do
      let(:type) { Object }

      context 'when the object is a BSON::ObjectId' do
        let(:object) { BSON::ObjectId.new }

        it 'returns the object id' do
          expect(mongoized).to eq(object)
        end
      end

      context 'when the object is a String which is a legal object id' do
        let(:object) { BSON::ObjectId.new.to_s }

        it 'returns the object id' do
          expect(mongoized).to eq(BSON::ObjectId.from_string(object))
        end
      end

      context 'when the object is a String which is not a legal object id' do
        let(:object) { 'blah' }

        it 'returns the string' do
          expect(mongoized).to eq('blah')
        end
      end

      context 'when the String is blank' do
        let(:object) { '' }

        it 'returns nil' do
          expect(mongoized).to be_nil
        end
      end

      context 'when the object is nil' do
        let(:object) { '' }

        it 'returns nil' do
          expect(mongoized).to be_nil
        end
      end

      context 'when object is an empty Array' do
        let(:object) { [] }

        it 'returns an empty array' do
          expect(mongoized).to eq([])
        end
      end

      context 'when the object is a Set' do
        let(:object) { Set['blah'] }

        it 'returns the set' do
          expect(mongoized).to eq(Set['blah'])
        end
      end

      context 'when foreign key is a String' do
        before do
          Person.field(:_id, type: String, overwrite: true)
        end

        after do
          Person.field(
            :_id,
            type: BSON::ObjectId,
            pre_processed: true,
            default: ->{ BSON::ObjectId.new },
            overwrite: true
          )
        end

        context 'when the object is a String' do
          let(:object) { '1' }

          it 'returns String' do
            expect(mongoized).to eq(object)
          end
        end

        context 'when the object is a BSON::ObjectId' do
          let(:object) { BSON::ObjectId.new }

          it 'converts to String' do
            expect(mongoized).to eq(object.to_s)
          end
        end

        context 'when the object is an Integer' do
          let(:object) { 1 }

          it 'converts to String' do
            expect(mongoized).to eq('1')
          end
        end
      end

      context 'when foreign key is an Integer' do
        before do
          Person.field(:_id, type: Integer, overwrite: true)
        end

        after do
          Person.field(
            :_id,
            type: BSON::ObjectId,
            pre_processed: true,
            default: ->{ BSON::ObjectId.new },
            overwrite: true
          )
        end

        context 'when the object is a String' do
          let(:object) { '1' }

          it 'converts to Integer' do
            expect(mongoized).to eq(1)
          end
        end

        context 'when the object is an Integer' do
          let(:object) { 1 }

          it 'returns Integer' do
            expect(mongoized).to eq(object)
          end
        end
      end
    end
  end

  describe "#resizable" do

    context "when the type is an array" do

      let(:field) do
        described_class.new(:vals, type: Array, default: [])
      end

      it "returns true" do
        expect(field).to be_resizable
      end
    end

    context "when the type is an object" do

      let(:field) do
        described_class.new(:vals, type: Object, default: [])
      end

      it "returns false" do
        expect(field).to_not be_resizable
      end
    end
  end

  context "when the foreign key points is a many to many" do

    context "when the related document stores non object ids" do

      let(:agent) do
        Agent.new(account_ids: [ true, false, 1, 2 ])
      end

      it "casts the ids on the initial set" do
        expect(agent.account_ids).to eq([ "true", "false", "1", "2" ])
      end
    end
  end
end
