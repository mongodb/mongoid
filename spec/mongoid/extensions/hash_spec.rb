# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Extensions::Hash do

  describe "#__evolve_object_id__" do

    context "when values have object id strings" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: object_id.to_s }
      end

      let(:evolved) do
        hash.__evolve_object_id__
      end

      it "converts each value in the hash" do
        expect(evolved[:field]).to eq(object_id)
      end
    end

    context "when values have object ids" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: object_id }
      end

      let(:evolved) do
        hash.__evolve_object_id__
      end

      it "converts each value in the hash" do
        expect(evolved[:field]).to eq(object_id)
      end
    end

    context "when values have empty strings" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: "" }
      end

      let(:evolved) do
        hash.__evolve_object_id__
      end

      it "retains the empty string values" do
        expect(evolved[:field]).to be_empty
      end
    end

    context "when values have nils" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: nil }
      end

      let(:evolved) do
        hash.__evolve_object_id__
      end

      it "retains the nil values" do
        expect(evolved[:field]).to be_nil
      end
    end
  end

  describe "#__mongoize_object_id__" do

    context "when values have object id strings" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: object_id.to_s }
      end

      let(:mongoized) do
        hash.__mongoize_object_id__
      end

      it "converts each value in the hash" do
        expect(mongoized[:field]).to eq(object_id)
      end
    end

    context "when values have object ids" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: object_id }
      end

      let(:mongoized) do
        hash.__mongoize_object_id__
      end

      it "converts each value in the hash" do
        expect(mongoized[:field]).to eq(object_id)
      end
    end

    context "when values have empty strings" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: "" }
      end

      let(:mongoized) do
        hash.__mongoize_object_id__
      end

      it "converts the empty strings to nil" do
        expect(mongoized[:field]).to be_nil
      end
    end

    context "when values have nils" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      let(:hash) do
        { field: nil }
      end

      let(:mongoized) do
        hash.__mongoize_object_id__
      end

      it "retains the nil values" do
        expect(mongoized[:field]).to be_nil
      end
    end
  end

  describe "#__consolidate__" do

    context "when the hash already contains the key" do

      context "when the $set is first" do

        let(:hash) do
          { "$set" => { name: "Tool" }, likes: 10, "$inc" => { plays: 1 }}
        end

        let(:consolidated) do
          hash.__consolidate__(Band)
        end

        it "moves the non hash values under the provided key" do
          expect(consolidated).to eq({
            "$set" => { 'name' => "Tool", likes: 10 }, "$inc" => { 'plays' => 1 }
          })
        end
      end

      context "when the $set is not first" do

        let(:hash) do
          { likes: 10, "$inc" => { plays: 1 }, "$set" => { name: "Tool" }}
        end

        let(:consolidated) do
          hash.__consolidate__(Band)
        end

        it "moves the non hash values under the provided key" do
          expect(consolidated).to eq({
            "$set" => { likes: 10, 'name' => "Tool" }, "$inc" => { 'plays' => 1 }
          })
        end
      end
    end

    context "when the hash does not contain the key" do

      let(:hash) do
        { likes: 10, "$inc" => { plays: 1 }, name: "Tool"}
      end

      let(:consolidated) do
        hash.__consolidate__(Band)
      end

      it "moves the non hash values under the provided key" do
        expect(consolidated).to eq({
          "$set" => { likes: 10, name: "Tool" }, "$inc" => { 'plays' => 1 }
        })
      end
    end
  end

  context "when the hash key is a string" do

    let(:hash) do
      { "100" => { "name" => "hundred" } }
    end

    let(:nested) do
      hash.__nested__("100.name")
    end

    it "should retrieve a nested value under the provided key" do
      expect(nested).to eq "hundred"
    end

    context 'and the value is falsey' do
      let(:hash) do
        { "100" => { "name" => false } }
      end
      it "should retrieve the falsey nested value under the provided key" do
        expect(nested).to eq false
      end
    end

    context 'and the value is nil' do
      let(:hash) do
        { "100" => { 0 => "Please don't return this value!" } }
      end
      it "should retrieve the nil nested value under the provided key" do
        expect(nested).to eq nil
      end
    end
  end

  context "when the hash key is an integer" do
    let(:hash) do
      { 100 => { "name" => "hundred" } }
    end

    let(:nested) do
      hash.__nested__("100.name")
    end

    it "should retrieve a nested value under the provided key" do
      expect(nested).to eq("hundred")
    end
  end

  context "when the parent key is not present" do

    let(:hash) do
      { "101" => { "name" => "hundred and one" } }
    end

    let(:nested) do
      hash.__nested__("100.name")
    end

    it "should return nil" do
      expect(nested).to eq(nil)
    end
  end

  describe ".demongoize" do

    let(:hash) do
      { field: 1 }
    end

    it "returns the hash" do
      expect(Hash.demongoize(hash)).to eq(hash)
    end

    context "when object is nil" do
      let(:demongoized) do
        Hash.demongoize(nil)
      end

      it "returns nil" do
        expect(demongoized).to be_nil
      end
    end

    context "when the object is uncastable" do
      let(:demongoized) do
        Hash.demongoize(1)
      end

      it "returns the object" do
        expect(demongoized).to eq(1)
      end
    end
  end

  describe ".mongoize" do

    context "when object isn't nil" do

      let(:date) do
        Date.new(2012, 1, 1)
      end

      let(:hash) do
        { date: date }
      end

      let(:mongoized) do
        Hash.mongoize(hash)
      end

      it "mongoizes each element in the hash" do
        expect(mongoized[:date]).to be_a(Time)
      end

      it "converts the elements properly" do
        expect(mongoized[:date]).to eq(Time.utc(2012, 1, 1, 0, 0, 0))
      end
    end

    context "when object is nil" do
      let(:mongoized) do
        Hash.mongoize(nil)
      end

      it "returns nil" do
        expect(mongoized).to be_nil
      end
    end

    context "when the object is uncastable" do
      let(:mongoized) do
        Hash.mongoize(1)
      end

      it "returns nil" do
        expect(mongoized).to be_nil
      end
    end
  end

  describe "#mongoize" do

    let(:date) do
      Date.new(2012, 1, 1)
    end

    let(:hash) do
      { date: date }
    end

    let(:mongoized) do
      hash.mongoize
    end

    it "mongoizes each element in the hash" do
      expect(mongoized[:date]).to be_a(Time)
    end

    it "converts the elements properly" do
      expect(mongoized[:date]).to eq(Time.utc(2012, 1, 1, 0, 0, 0))
    end
  end

  describe "#resizable?" do

    it "returns true" do
      expect({}).to be_resizable
    end
  end

  describe ".resizable?" do

    it "returns true" do
      expect(Hash).to be_resizable
    end
  end

  shared_examples_for 'unsatisfiable criteria method' do

    context "when the hash has only an empty _id criteria" do

      let(:hash) do
        { "_id" => { "$in" => [] }}
      end

      it "is true" do
        expect(hash.send(meth)).to be true
      end
    end

    context "when the hash has an empty _id criteria and another criteria" do

      let(:hash) do
        { "_id" => { "$in" => [] }, 'foo' => 'bar'}
      end

      it "is false" do
        expect(hash.send(meth)).to be false
      end
    end

    context "when the hash has an empty _id criteria via $and" do

      let(:hash) do
        {'$and' => [{ "_id" => { "$in" => [] }}]}
      end

      it "is true" do
        expect(hash.send(meth)).to be true
      end
    end

    context "when the hash has an empty _id criteria via $and and another criteria at top level" do

      let(:hash) do
        {'$and' => [{ "_id" => { "$in" => [] }}], 'foo' => 'bar'}
      end

      it "is false" do
        expect(hash.send(meth)).to be false
      end
    end

    context "when the hash has an empty _id criteria via $and and another criteria in $and" do

      let(:hash) do
        {'$and' => [{ "_id" => { "$in" => [] }}, {'foo' => 'bar'}]}
      end

      it "is true" do
        expect(hash.send(meth)).to be true
      end
    end

    context "when the hash has an empty _id criteria via $and and another criteria in $and value" do

      let(:hash) do
        {'$and' => [{ "_id" => { "$in" => [] }, 'foo' => 'bar'}]}
      end

      it "is false" do
        expect(hash.send(meth)).to be false
      end
    end

    context "when the hash has an empty _id criteria via $or" do

      let(:hash) do
        {'$or' => [{ "_id" => { "$in" => [] }}]}
      end

      it "is false" do
        expect(hash.send(meth)).to be false
      end
    end

    context "when the hash has an empty _id criteria via $nor" do

      let(:hash) do
        {'$nor' => [{ "_id" => { "$in" => [] }}]}
      end

      it "is false" do
        expect(hash.send(meth)).to be false
      end
    end
  end

  describe "#blank_criteria?" do
    let(:meth) { :blank_criteria? }

    it_behaves_like 'unsatisfiable criteria method'
  end

  describe "#_mongoid_unsatisfiable_criteria?" do
    let(:meth) { :_mongoid_unsatisfiable_criteria? }

    it_behaves_like 'unsatisfiable criteria method'
  end

  describe '#to_criteria' do
    subject(:criteria) { hash.to_criteria }

    context 'when klass is specified' do
      let(:hash) do
        { klass: Band, where: { name: 'Songs Ohia' } }
      end

      it 'returns a criteria' do
        expect(criteria).to be_a(Mongoid::Criteria)
      end

      it 'sets the klass' do
        expect(criteria.klass).to eq(Band)
      end

      it 'sets the selector' do
        expect(criteria.selector).to eq({ 'name' => 'Songs Ohia' })
      end
    end

    context 'when klass is missing' do
      let(:hash) do
        { where: { name: 'Songs Ohia' } }
      end

      it 'returns a criteria' do
        expect(criteria).to be_a(Mongoid::Criteria)
      end

      it 'has klass nil' do
        expect(criteria.klass).to be_nil
      end

      it 'sets the selector' do
        expect(criteria.selector).to eq({ 'name' => 'Songs Ohia' })
      end
    end

    context 'with allowed methods' do
      context 'when using multiple query methods' do
        let(:hash) do
          {
            klass: Band,
            where: { active: true },
            limit: 10,
            skip: 5,
            order_by: { name: 1 }
          }
        end

        it 'applies all methods successfully' do
          expect(criteria.selector).to eq({ 'active' => true })
          expect(criteria.options[:limit]).to eq(10)
          expect(criteria.options[:skip]).to eq(5)
          expect(criteria.options[:sort]).to eq({ 'name' => 1 })
        end
      end

      context 'when using query selector methods' do
        let(:hash) do
          {
            klass: Band,
            gt: { members: 2 },
            in: { genre: ['rock', 'metal'] }
          }
        end

        it 'applies selector methods' do
          expect(criteria.selector['members']).to eq({ '$gt' => 2 })
          expect(criteria.selector['genre']).to eq({ '$in' => ['rock', 'metal'] })
        end
      end

      context 'when using aggregation methods' do
        let(:hash) do
          {
            klass: Band,
            project: { name: 1, members: 1 }
          }
        end

        it 'applies aggregation methods' do
          expect { criteria }.not_to raise_error
        end
      end
    end

    context 'with disallowed methods' do
      context 'when attempting to call create' do
        let(:hash) do
          { klass: Band, create: { name: 'Malicious' } }
        end

        it 'raises ArgumentError' do
          expect { criteria }.to raise_error(ArgumentError, "Method 'create' is not allowed in to_criteria")
        end
      end

      context 'when attempting to call create!' do
        let(:hash) do
          { klass: Band, 'create!': { name: 'Malicious' } }
        end

        it 'raises ArgumentError' do
          expect { criteria }.to raise_error(ArgumentError, "Method 'create!' is not allowed in to_criteria")
        end
      end

      context 'when attempting to call build' do
        let(:hash) do
          { klass: Band, build: { name: 'Malicious' } }
        end

        it 'raises ArgumentError' do
          expect { criteria }.to raise_error(ArgumentError, "Method 'build' is not allowed in to_criteria")
        end
      end

      context 'when attempting to call find' do
        let(:hash) do
          { klass: Band, find: 'some_id' }
        end

        it 'raises ArgumentError' do
          expect { criteria }.to raise_error(ArgumentError, "Method 'find' is not allowed in to_criteria")
        end
      end

      context 'when attempting to call execute_or_raise' do
        let(:hash) do
          { klass: Band, execute_or_raise: ['id1', 'id2'] }
        end

        it 'raises ArgumentError' do
          expect { criteria }.to raise_error(ArgumentError, "Method 'execute_or_raise' is not allowed in to_criteria")
        end
      end

      context 'when attempting to call new' do
        let(:hash) do
          { klass: Band, new: { name: 'Test' } }
        end

        it 'raises ArgumentError' do
          expect { criteria }.to raise_error(ArgumentError, "Method 'new' is not allowed in to_criteria")
        end
      end

      context 'when allowed method is combined with disallowed method' do
        let(:hash) do
          {
            klass: Band,
            where: { active: true },
            create: { name: 'Malicious' }
          }
        end

        it 'raises ArgumentError before executing any methods' do
          expect { criteria }.to raise_error(ArgumentError, "Method 'create' is not allowed in to_criteria")
        end
      end
    end

    context 'security validation' do
      # This test ensures that ALL public methods not in the allowlist are blocked
      it 'blocks all dangerous public methods' do
        dangerous_methods = %i[
          build create create! new
          find find_or_create_by find_or_create_by! find_or_initialize_by
          first_or_create first_or_create! first_or_initialize
          execute_or_raise multiple_from_db for_ids
          documents= inclusions= scoping_options=
          initialize freeze as_json
        ]

        dangerous_methods.each do |method|
          hash = { klass: Band, method => 'arg' }
          expect { hash.to_criteria }.to raise_error(
            ArgumentError,
            "Method '#{method}' is not allowed in to_criteria"
          ), "Expected method '#{method}' to be blocked but it was allowed"
        end
      end

      it 'blocks dangerous inherited methods from Object' do
        # Critical security test: block send, instance_eval, etc.
        inherited_dangerous = %i[
          send __send__ instance_eval instance_exec
          instance_variable_set method
        ]

        inherited_dangerous.each do |method|
          hash = { klass: Band, method => 'arg' }
          expect { hash.to_criteria }.to raise_error(
            ArgumentError,
            "Method '#{method}' is not allowed in to_criteria"
          ), "Expected inherited method '#{method}' to be blocked"
        end
      end

      it 'blocks Enumerable execution methods' do
        # to_criteria should build queries, not execute them
        enumerable_methods = %i[each map select count sum]

        enumerable_methods.each do |method|
          hash = { klass: Band, method => 'arg' }
          expect { hash.to_criteria }.to raise_error(
            ArgumentError,
            "Method '#{method}' is not allowed in to_criteria"
          ), "Expected Enumerable method '#{method}' to be blocked"
        end
      end

      it 'allows all whitelisted methods' do
        # Sample of allowed methods from each category
        allowed_sample = {
          where: { name: 'Test' },      # Query selector
          limit: 10,                     # Query option
          skip: 5,                       # Query option
          gt: { age: 18 },              # Query selector
          in: { status: ['active'] },   # Query selector
          ascending: :name,              # Sorting
          includes: :notes,            # Eager loading
          merge: { klass: Band },        # Merge
        }

        allowed_sample.each do |method, args|
          hash = { klass: Band, method => args }
          expect { hash.to_criteria }.not_to raise_error,
            "Expected method '#{method}' to be allowed but it was blocked"
        end
      end
    end
  end
end
