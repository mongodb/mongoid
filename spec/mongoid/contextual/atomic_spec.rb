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

    let(:criteria) do
      Band.all
    end

    let(:context) do
      Mongoid::Contextual::Mongo.new(criteria)
    end

    before do
      context.add_to_set(:members, "Dave")
    end

    it "does not add duplicates" do
      depeche_mode.reload.members.should eq([ "Dave" ])
    end

    it "adds unique values" do
      new_order.reload.members.should eq([ "Peter", "Dave" ])
    end

    it "adds to non initialized fields" do
      smiths.reload.members.should eq([ "Dave" ])
    end
  end

  describe "#bit" do

    let!(:depeche_mode) do
      Band.create(likes: 60)
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

    context "when performing a bitwise and" do

      before do
        context.bit(:likes, { and: 13 })
      end

      it "performs the bitwise operation on initialized fields" do
        depeche_mode.reload.likes.should eq(12)
      end

      it "does not error on non initialized fields" do
        smiths.reload.likes.should be_nil
      end
    end

    context "when performing a bitwise or" do

      before do
        context.bit(:likes, { or: 13 })
      end

      it "performs the bitwise operation on initialized fields" do
        depeche_mode.reload.likes.should eq(61)
      end

      it "does not error on non initialized fields" do
        smiths.reload.likes.should be_nil
      end
    end

    context "when chaining bitwise operations" do

      before do
        context.bit(:likes, { and: 13, or: 10 })
      end

      it "performs the bitwise operation on initialized fields" do
        depeche_mode.reload.likes.should eq(14)
      end

      it "does not error on non initialized fields" do
        smiths.reload.likes.should be_nil
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

    let(:criteria) do
      Band.all
    end

    let(:context) do
      Mongoid::Contextual::Mongo.new(criteria)
    end

    before do
      context.inc(:likes, 10)
    end

    context "when the field exists" do

      it "incs the value" do
        depeche_mode.reload.likes.should eq(70)
      end
    end

    context "when the field does not exist" do

      it "does not error on the inc" do
        smiths.likes.should be_nil
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
        context.pop(:members, -1)
      end

      it "pops the first element off the array" do
        depeche_mode.reload.members.should eq([ "Martin" ])
      end

      it "does not error on uninitialized fields" do
        smiths.reload.members.should be_nil
      end
    end

    context "when popping from the rear" do

      before do
        context.pop(:members, 1)
      end

      it "pops the last element off the array" do
        depeche_mode.reload.members.should eq([ "Dave" ])
      end

      it "does not error on uninitialized fields" do
        smiths.reload.members.should be_nil
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
      context.pull(:members, "Alan")
    end

    it "pulls when the value is found" do
      depeche_mode.reload.members.should eq([ "Dave" ])
    end

    it "does not error on non existant fields" do
      smiths.reload.members.should be_nil
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
      context.pull_all(:members, [ "Alan", "Dave" ])
    end

    it "pulls when the values are found" do
      depeche_mode.reload.members.should eq([ "Fletch" ])
    end

    it "does not error on non existant fields" do
      smiths.reload.members.should be_nil
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
      context.push(:members, "Alan")
    end

    it "pushes the value to existing arrays" do
      depeche_mode.reload.members.should eq([ "Dave", "Alan" ])
    end

    it "pushes to non existant fields" do
      smiths.reload.members.should eq([ "Alan" ])
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
      context.push_all(:members, [ "Alan", "Fletch" ])
    end

    it "pushes the values to existing arrays" do
      depeche_mode.reload.members.should eq([ "Dave", "Alan", "Fletch" ])
    end

    it "pushes to non existant fields" do
      smiths.reload.members.should eq([ "Alan", "Fletch" ])
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
      context.rename(:members, :artists)
    end

    it "renames existing fields" do
      depeche_mode.reload.artists.should eq([ "Dave" ])
    end

    it "does not rename non existant fields" do
      smiths.reload.should_not respond_to(:artists)
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
      context.set(:name, "Recoil")
    end

    it "sets existing fields" do
      depeche_mode.reload.name.should eq("Recoil")
    end

    it "sets non existant fields" do
      smiths.reload.name.should eq("Recoil")
    end
  end

  describe "#unset" do

    let!(:depeche_mode) do
      Band.create(name: "Depeche Mode")
    end

    let!(:new_order) do
      Band.create(name: "New Order")
    end

    let(:criteria) do
      Band.all
    end

    let(:context) do
      Mongoid::Contextual::Mongo.new(criteria)
    end

    before do
      context.unset(:name)
    end

    it "unsets the first existing field" do
      depeche_mode.reload.name.should be_nil
    end

    it "unsets the last existing field" do
      new_order.reload.name.should be_nil
    end
  end
end
