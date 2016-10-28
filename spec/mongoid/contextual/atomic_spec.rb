require "spec_helper"

describe Mongoid::Contextual::Atomic do

  describe "#add_to_set" do

    let!(:depeche_mode) do
      Band.create(members: [ "Dave" ])
    end

    let!(:new_order) do
      Band.create(members: [ "Peter" ])
    end

    let!(:smiths) do
      Band.create
    end

    context "when the criteria has no sorting" do

      let(:criteria) do
        Band.all
      end

      let(:context) do
        Mongoid::Contextual::Mongo.new(criteria)
      end

      before do
        context.add_to_set(members: "Dave")
      end

      it "does not add duplicates" do
        expect(depeche_mode.reload.members).to eq([ "Dave" ])
      end

      it "adds unique values" do
        expect(new_order.reload.members).to eq([ "Peter", "Dave" ])
      end

      it "adds to non initialized fields" do
        expect(smiths.reload.members).to eq([ "Dave" ])
      end
    end

    context "when the criteria has sorting" do

      let(:criteria) do
        Band.asc(:name)
      end

      let(:context) do
        Mongoid::Contextual::Mongo.new(criteria)
      end

      before do
        context.add_to_set(members: "Dave", genres: "Electro")
      end

      it "does not add duplicates" do
        expect(depeche_mode.reload.members).to eq([ "Dave" ])
      end

      it "adds multiple operations" do
        expect(depeche_mode.reload.genres).to eq([ "Electro" ])
      end

      it "adds unique values" do
        expect(new_order.reload.members).to eq([ "Peter", "Dave" ])
      end

      it "adds to non initialized fields" do
        expect(smiths.reload.members).to eq([ "Dave" ])
      end
    end
  end

  describe "#bit" do

    let!(:depeche_mode) do
      Band.create(likes: 60)
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      Mongoid::Contextual::Mongo.new(criteria)
    end

    context "when performing a bitwise and" do

      before do
        context.bit(likes: { and: 13 })
      end

      it "performs the bitwise operation on initialized fields" do
        expect(depeche_mode.reload.likes).to eq(12)
      end
    end

    context "when performing a bitwise or" do

      before do
        context.bit(likes: { or: 13 })
      end

      it "performs the bitwise operation on initialized fields" do
        expect(depeche_mode.reload.likes).to eq(61)
      end
    end

    context "when chaining bitwise operations" do

      before do
        context.bit(likes: { and: 13, or: 10 })
      end

      it "performs the bitwise operation on initialized fields" do
        expect(depeche_mode.reload.likes).to eq(14)
      end
    end
  end

  describe "#inc" do

    let!(:depeche_mode) do
      Band.create(likes: 60)
    end

    let!(:smiths) do
      Band.create
    end

    let!(:beatles) do
      Band.create(years: 2)
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      Mongoid::Contextual::Mongo.new(criteria)
    end

    before do
      context.inc(likes: 10)
    end

    context "when the field exists" do

      it "incs the value" do
        expect(depeche_mode.reload.likes).to eq(70)
      end
    end

    context "when the field does not exist" do

      it "does not error on the inc" do
        expect(smiths.likes).to be_nil
      end
    end

    context "when using the alias" do

      before do
        context.inc(years: 1)
      end

      it "incs the value and read from alias" do
        expect(beatles.reload.years).to eq(3)
      end

      it "incs the value and read from field" do
        expect(beatles.reload.y).to eq(3)
      end
    end
  end

  describe "#pop" do

    let!(:depeche_mode) do
      Band.create(members: [ "Dave", "Martin" ])
    end

    let!(:smiths) do
      Band.create
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      Mongoid::Contextual::Mongo.new(criteria)
    end

    context "when popping from the front" do

      before do
        context.pop(members: -1)
      end

      it "pops the first element off the array" do
        expect(depeche_mode.reload.members).to eq([ "Martin" ])
      end

      it "does not error on uninitialized fields" do
        expect(smiths.reload.members).to be_nil
      end
    end

    context "when popping from the rear" do

      before do
        context.pop(members: 1)
      end

      it "pops the last element off the array" do
        expect(depeche_mode.reload.members).to eq([ "Dave" ])
      end

      it "does not error on uninitialized fields" do
        expect(smiths.reload.members).to be_nil
      end
    end
  end

  describe "#pull" do

    let!(:depeche_mode) do
      Band.create(members: [ "Dave", "Alan" ])
    end

    let!(:smiths) do
      Band.create
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      Mongoid::Contextual::Mongo.new(criteria)
    end

    before do
      context.pull(members: "Alan")
    end

    it "pulls when the value is found" do
      expect(depeche_mode.reload.members).to eq([ "Dave" ])
    end

    it "does not error on non existent fields" do
      expect(smiths.reload.members).to be_nil
    end
  end

  describe "#pull_all" do

    let!(:depeche_mode) do
      Band.create(members: [ "Dave", "Alan", "Fletch" ])
    end

    let!(:smiths) do
      Band.create
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      Mongoid::Contextual::Mongo.new(criteria)
    end

    before do
      context.pull_all(members: [ "Alan", "Dave" ])
    end

    it "pulls when the values are found" do
      expect(depeche_mode.reload.members).to eq([ "Fletch" ])
    end

    it "does not error on non existent fields" do
      expect(smiths.reload.members).to be_nil
    end
  end

  describe "#push" do

    let!(:depeche_mode) do
      Band.create(members: [ "Dave" ])
    end

    let!(:smiths) do
      Band.create
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      Mongoid::Contextual::Mongo.new(criteria)
    end

    before do
      context.push(members: "Alan")
    end

    it "pushes the value to existing arrays" do
      expect(depeche_mode.reload.members).to eq([ "Dave", "Alan" ])
    end

    it "pushes to non existent fields" do
      expect(smiths.reload.members).to eq([ "Alan" ])
    end
  end

  describe "#push_all" do

    let!(:depeche_mode) do
      Band.create(members: [ "Dave" ])
    end

    let!(:smiths) do
      Band.create
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      Mongoid::Contextual::Mongo.new(criteria)
    end

    before do
      context.push_all(members: [ "Alan", "Fletch" ])
    end

    it "pushes the values to existing arrays" do
      expect(depeche_mode.reload.members).to eq([ "Dave", "Alan", "Fletch" ])
    end

    it "pushes to non existent fields" do
      expect(smiths.reload.members).to eq([ "Alan", "Fletch" ])
    end
  end

  describe "#rename" do

    let!(:depeche_mode) do
      Band.create(members: [ "Dave" ])
    end

    let!(:smiths) do
      Band.create
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      Mongoid::Contextual::Mongo.new(criteria)
    end

    before do
      context.rename(members: :artists)
    end

    it "renames existing fields" do
      expect(depeche_mode.reload.artists).to eq([ "Dave" ])
    end

    it "does not rename non existent fields" do
      expect(smiths.reload).to_not respond_to(:artists)
    end
  end

  describe "#set" do

    let!(:depeche_mode) do
      Band.create(name: "Depeche Mode")
    end

    let!(:smiths) do
      Band.create
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      Mongoid::Contextual::Mongo.new(criteria)
    end

    before do
      context.set(name: "Recoil")
    end

    it "sets existing fields" do
      expect(depeche_mode.reload.name).to eq("Recoil")
    end

    it "sets non existent fields" do
      expect(smiths.reload.name).to eq("Recoil")
    end
  end

  describe "#unset" do

    context "when unsetting a single field" do

      let!(:depeche_mode) do
        Band.create(name: "Depeche Mode", years: 10)
      end

      let!(:new_order) do
        Band.create(name: "New Order", years: 10)
      end

      let(:criteria) do
        Band.all
      end

      let(:context) do
        Mongoid::Contextual::Mongo.new(criteria)
      end

      context "when the field is not aliased" do

        before do
          context.unset(:name)
        end

        it "unsets the first existing field" do
          expect(depeche_mode.reload.name).to be_nil
        end

        it "unsets the last existing field" do
          expect(new_order.reload.name).to be_nil
        end
      end

      context "when the field is aliased" do

        before do
          context.unset(:years)
        end

        it "unsets the first existing field" do
          expect(depeche_mode.reload.years).to be_nil
        end

        it "unsets the last existing field" do
          expect(new_order.reload.years).to be_nil
        end
      end
    end

    context "when unsetting multiple fields" do

      let!(:new_order) do
        Band.create(name: "New Order", genres: [ "electro", "dub" ], years: 10)
      end

      let(:criteria) do
        Band.all
      end

      let(:context) do
        Mongoid::Contextual::Mongo.new(criteria)
      end

      context "when the field is not aliased" do

        before do
          context.unset(:name, :genres)
        end

        it "unsets name field" do
          expect(new_order.reload.name).to be_nil
        end

        it "unsets genres field" do
          expect(new_order.reload.genres).to be_nil
        end
      end

      context "when the field is aliased" do

        before do
          context.unset(:name, :years)
        end

        it "unsets the unaliased field" do
          expect(new_order.reload.name).to be_nil
        end

        it "unsets the aliased field" do
          expect(new_order.reload.years).to be_nil
        end
      end
    end
  end
end
