# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Contextual::Atomic do

  describe "#add_to_set" do

    let!(:depeche_mode) do
      Band.create!(members: [ "Dave" ])
    end

    let!(:new_order) do
      Band.create!(members: [ "Peter" ])
    end

    let!(:smiths) do
      Band.create!
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

    context 'when the criteria has a collation' do
      min_server_version '3.4'

      let(:criteria) do
        Band.where(members: [ "DAVE" ]).collation(locale: 'en_US', strength: 2)
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
    end
  end

  describe "#add_each_to_set" do

    let!(:depeche_mode) do
      Band.create!(members: [ "Dave" ])
    end

    let!(:new_order) do
      Band.create!(members: [ "Peter" ])
    end

    let!(:smiths) do
      Band.create!
    end

    context "when the criteria has no sorting" do

      let(:criteria) do
        Band.all
      end

      let(:context) do
        Mongoid::Contextual::Mongo.new(criteria)
      end

      before do
        context.add_each_to_set(members: [ "Dave", "Joe" ])
      end

      it "does not add duplicates" do
        expect(depeche_mode.reload.members).to eq([ "Dave", "Joe" ])
      end

      it "adds unique values" do
        expect(new_order.reload.members).to eq([ "Peter", "Dave", "Joe" ])
      end

      it "adds to non initialized fields" do
        expect(smiths.reload.members).to eq([ "Dave", "Joe" ])
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
        context.add_each_to_set(members: [ "Dave", "Joe" ], genres: "Electro")
      end

      it "does not add duplicates" do
        expect(depeche_mode.reload.members).to eq([ "Dave", "Joe" ])
      end

      it "adds multiple operations" do
        expect(depeche_mode.reload.genres).to eq([ "Electro" ])
      end

      it "adds unique values" do
        expect(new_order.reload.members).to eq([ "Peter", "Dave", "Joe" ])
      end

      it "adds to non initialized fields" do
        expect(smiths.reload.members).to eq([ "Dave", "Joe" ])
      end
    end

    context 'when the criteria has a collation' do
      min_server_version '3.4'

      let(:criteria) do
        Band.where(members: [ "DAVE" ]).collation(locale: 'en_US', strength: 2)
      end

      let(:context) do
        Mongoid::Contextual::Mongo.new(criteria)
      end

      before do
        context.add_each_to_set(members: [ "Dave", "Joe" ], genres: "Electro")
      end

      it "does not add duplicates" do
        expect(depeche_mode.reload.members).to eq([ "Dave", "Joe" ])
      end

      it "adds multiple operations" do
        expect(depeche_mode.reload.genres).to eq([ "Electro" ])
      end
    end
  end

  describe "#bit" do

    let!(:depeche_mode) do
      Band.create!(likes: 60)
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

    context 'when the criteria has a collation' do
      min_server_version '3.4'

      let!(:depeche_mode) do
        Band.create!(members: [ "Dave" ], likes: 60)
      end

      let(:criteria) do
        Band.where(members: [ "DAVE" ]).collation(locale: 'en_US', strength: 2)
      end

      let(:context) do
        Mongoid::Contextual::Mongo.new(criteria)
      end

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
      Band.create!(likes: 60)
    end

    let!(:smiths) do
      Band.create!
    end

    let!(:beatles) do
      Band.create!(years: 2)
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

    context 'when the criteria has a collation' do
      min_server_version '3.4'

      let!(:depeche_mode) do
        Band.create!(members: [ "Dave" ])
      end

      let(:criteria) do
        Band.where(members: [ "DAVE" ]).collation(locale: 'en_US', strength: 2)
      end

      let(:context) do
        Mongoid::Contextual::Mongo.new(criteria)
      end

      before do
        context.inc(years: 1)
      end

      it "incs the value and read from alias" do
        expect(depeche_mode.reload.years).to eq(1)
      end
    end
  end

  describe "#pop" do

    let!(:depeche_mode) do
      Band.create!(members: [ "Dave", "Martin" ])
    end

    let!(:smiths) do
      Band.create!
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

    context 'when the criteria has a collation' do
      min_server_version '3.4'

      let!(:depeche_mode) do
        Band.create!(members: [ "Dave" ])
      end

      let(:criteria) do
        Band.where(members: [ "DAVE" ]).collation(locale: 'en_US', strength: 2)
      end

      let(:context) do
        Mongoid::Contextual::Mongo.new(criteria)
      end

      before do
        context.pop(members: 1)
      end

      it "pops the last element off the array" do
        expect(depeche_mode.reload.members).to be_empty
      end
    end
  end

  describe "#pull" do

    let!(:depeche_mode) do
      Band.create!(members: [ "Dave", "Alan" ])
    end

    let!(:smiths) do
      Band.create!
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

    context 'when the criteria has a collation' do
      min_server_version '3.4'

      let!(:depeche_mode) do
        Band.create!(members: [ "Dave" ])
      end

      let(:criteria) do
        Band.where(members: [ "DAVE" ]).collation(locale: 'en_US', strength: 2)
      end

      let(:context) do
        Mongoid::Contextual::Mongo.new(criteria)
      end

      before do
        context.pull(members: "DAVE")
      end

      it "pulls when the value is found" do
        expect(depeche_mode.reload.members).to be_empty
      end
    end
  end

  describe "#pull_all" do

    context 'when the criteria does not have a collation' do

      let!(:depeche_mode) do
        Band.create!(members: [ "Dave", "Alan", "Fletch" ])
      end

      let!(:smiths) do
        Band.create!
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

    context 'when the criteria has a collation' do
      min_server_version '3.4'

      let!(:depeche_mode) do
        Band.create!(members: [ "Dave", "Alan", "Fletch" ])
      end

      let(:criteria) do
        Band.all.collation(locale: 'en_US', strength: 2)
      end

      let(:context) do
        Mongoid::Contextual::Mongo.new(criteria)
      end

      before do
        context.pull_all(members: [ "ALAN", "DAVE" ])
      end

      it "pulls when the value is found" do
        expect(depeche_mode.reload.members).to eq([ "Fletch" ])
      end
    end
  end

  describe "#push" do

    context 'when the criteria does not have a collation' do

      let!(:depeche_mode) do
        Band.create!(members: [ "Dave" ])
      end

      let!(:smiths) do
        Band.create!
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

    context 'when the criteria has a collation' do
      min_server_version '3.4'

      let!(:depeche_mode) do
        Band.create!(members: [ "Dave" ])
      end

      let!(:smiths) do
        Band.create!
      end

      let(:criteria) do
        Band.where(members: ['DAVE']).collation(locale: 'en_US', strength: 2)
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
        expect(smiths.reload.members).to be_nil
      end
    end
  end

  describe "#push_all" do

    context 'when the criteria does not have a collation' do

      let!(:depeche_mode) do
        Band.create!(members: [ "Dave" ])
      end

      let!(:smiths) do
        Band.create!
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

    context 'when the criteria has a collation' do
      min_server_version '3.4'

      let!(:depeche_mode) do
        Band.create!(members: [ "Dave" ])
      end

      let!(:smiths) do
        Band.create!
      end

      let(:criteria) do
        Band.where(members: ['DAVE']).collation(locale: 'en_US', strength: 2)
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
    end
  end

  describe "#rename" do

    context 'when the criteria does not have a collation' do

      let!(:depeche_mode) do
        Band.create!(members: [ "Dave" ])
      end

      let!(:smiths) do
        Band.create!
      end

      let(:criteria) do
        Band.all
      end

      let(:context) do
        Mongoid::Contextual::Mongo.new(criteria)
      end

      before do
        context.rename(members: :musicians)
      end

      it "renames existing fields" do
        expect(depeche_mode.reload.musicians).to eq([ "Dave" ])
      end

      it "does not rename non existent fields" do
        expect(smiths.reload).to_not respond_to(:musicians)
      end
    end

    context 'when the criteria has a collation' do
      min_server_version '3.4'

      let!(:depeche_mode) do
        Band.create!(members: [ "Dave" ])
      end

      let!(:smiths) do
        Band.create!
      end

      let(:criteria) do
        Band.where(members: ['DAVE']).collation(locale: 'en_US', strength: 2)
      end

      let(:context) do
        Mongoid::Contextual::Mongo.new(criteria)
      end

      before do
        context.rename(members: :musicians)
      end

      it "renames existing fields" do
        expect(depeche_mode.reload.musicians).to eq([ "Dave" ])
      end

      it "does not rename non existent fields" do
        expect(smiths.reload).to_not respond_to(:musicians)
      end
    end
  end

  describe "#set" do

    let!(:depeche_mode) do
      Band.create!(name: "Depeche Mode")
    end

    let!(:smiths) do
      Band.create!
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

    shared_examples 'writes as expected' do
      it "sets existing fields" do
        expect(depeche_mode.reload.name).to eq("Recoil")
      end

      it "sets non existent fields" do
        expect(smiths.reload.name).to eq("Recoil")
      end
    end

    include_examples 'writes as expected'

    context 'when fields being set have been projected out' do

      let(:criteria) do
        Band.only(:genres)
      end

      include_examples 'writes as expected'
    end
  end

  describe "#unset" do

    context "when unsetting a single field" do

      let!(:depeche_mode) do
        Band.create!(name: "Depeche Mode", years: 10)
      end

      let!(:new_order) do
        Band.create!(name: "New Order", years: 10)
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

        it "unsets the fields from all documents" do
          depeche_mode.reload
          new_order.reload
          expect(depeche_mode.name).to be_nil
          expect(depeche_mode.years).to_not be_nil
          expect(new_order.name).to be_nil
          expect(new_order.years).to_not be_nil
        end
      end

      context "when the field is aliased" do
        before do
          context.unset(:years)
        end

        it "unsets the fields from all documents" do
          depeche_mode.reload
          new_order.reload
          expect(depeche_mode.name).to_not be_nil
          expect(depeche_mode.years).to be_nil
          expect(new_order.name).to_not be_nil
          expect(new_order.years).to be_nil
        end
      end
    end

    context "when unsetting multiple fields" do

      let!(:new_order) do
        Band.create!(name: "New Order", genres: %w[electro dub], years: 10,
          likes: 200, rating: 4.3, origin: 'Space')
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

        it "unsets the specified fields" do
          new_order.reload
          expect(new_order.name).to be_nil
          expect(new_order.genres).to be_nil
          expect(new_order.years).to_not be_nil
          expect(new_order.likes).to_not be_nil
          expect(new_order.rating).to_not be_nil
        end
      end

      context "when the field is aliased" do

        before do
          context.unset(:name, :years)
        end

        it "unsets the specified fields" do
          new_order.reload
          expect(new_order.name).to be_nil
          expect(new_order.genres).to_not be_nil
          expect(new_order.years).to be_nil
          expect(new_order.likes).to_not be_nil
          expect(new_order.rating).to_not be_nil
        end
      end

      context "when using Hash arguments" do

        before do
          context.unset({ years: true, likes: "" }, { rating: false, origin: nil })
        end

        it "unsets the specified fields" do
          new_order.reload
          expect(new_order.name).to_not be_nil
          expect(new_order.genres).to_not be_nil
          expect(new_order.years).to be_nil
          expect(new_order.likes).to be_nil
          expect(new_order.rating).to be_nil
          expect(new_order.origin).to be_nil
        end
      end

      context "when mixing argument types" do

        before do
          context.unset(:name, [:years], { likes: "" }, { rating: false })
        end

        it "unsets the specified fields" do
          new_order.reload
          expect(new_order.name).to be_nil
          expect(new_order.genres).to_not be_nil
          expect(new_order.years).to be_nil
          expect(new_order.likes).to be_nil
          expect(new_order.rating).to be_nil
        end
      end
    end

    context 'when the criteria has a collation' do
      min_server_version '3.4'

      let!(:depeche_mode) do
        Band.create!(name: "Depeche Mode", years: 10)
      end

      let!(:new_order) do
        Band.create!(name: "New Order", years: 10)
      end

      let(:criteria) do
        Band.where(name: 'DEPECHE MODE').collation(locale: 'en_US', strength: 2)
      end

      let(:context) do
        Mongoid::Contextual::Mongo.new(criteria)
      end

      before do
        context.unset(:name)
      end

      it "unsets the unaliased field" do
        depeche_mode.reload
        expect(depeche_mode.name).to be_nil
        expect(depeche_mode.years).to_not be_nil
      end
    end
  end

  describe '#current_date' do
    let!(:tmbg) { Band.create! }
    let(:criteria) { Band.all }
    let(:context) { Mongoid::Contextual::Mongo.new(criteria) }
    
    context 'when the field does not exist' do
      it 'creates the field' do
        context.current_date(significant_date: true)
        expect(tmbg.reload[:significant_date]).to be > 1.second.ago
      end
    end

    context 'when an using a symbolic type' do
      context 'when the type is implied' do
        it 'assumes the type is `true`' do
          context.current_date(:founded)
          expect(tmbg.reload.founded).to be == Date.today
        end
      end

      context 'when the type is known' do
        it 'accepts the type' do
          context.current_date(founded: :date)
          expect(tmbg.reload.founded).to be == Date.today
        end
      end

      context 'when the type is unknown' do
        it 'raises an exception' do
          expect { context.current_date(founded: :bogus) }
            .to raise_error(Mongo::Error::OperationFailure)
        end
      end

      context 'with mixed argument types' do
        it 'accepts the arguments' do
          context.current_date(:created, founded: :date)
          expect(tmbg.reload.founded).to be == Date.today
          expect(tmbg.created).to be > 1.second.ago
        end
      end
    end
  end

  describe '#update_min' do
    let(:member_count) { 5 }
    let(:views) { 25_000 }
    let(:founded) { 2.years.ago.to_date }
    let(:decimal) { 3.1415 }

    let!(:band) do
      Band.create!(
        member_count: member_count,
        founded: founded,
        views: views)
    end

    let(:criteria) { Band.all }
    let(:context) { Mongoid::Contextual::Mongo.new(criteria) }

    shared_examples_for 'a min-able context' do
      it 'chooses the smaller value' do
        context.update_min("member_count" => given_members, views: given_views)
        expect(band.reload.member_count).to be == [ member_count, given_members ].min
        expect(band.views).to be == [ views, given_views ].min
      end
    end

    context 'when given value < existing value' do
      let(:given_views) { views - 1 }
      let(:given_members) { member_count - 1 }

      it_behaves_like 'a min-able context'
    end

    context 'when given value == existing value' do
      let(:given_views) { views }
      let(:given_members) { member_count }

      it_behaves_like 'a min-able context'
    end

    context 'when given value > existing value' do
      let(:given_views) { views + 1 }
      let(:given_members) { member_count + 1 }

      it_behaves_like 'a min-able context'
    end

    context 'when the named field does not yet exist on the document' do
      it 'sets the field to the argument' do
        context.update_min(new_field: 100)
        expect(band.reload.new_field).to be == 100
      end
    end

    context 'when arguments are dates/times' do
      it 'picks the earliest date' do
        context.update_min(founded: founded - 1)
        expect(band.reload.founded).to be == founded - 1
      end
    end
  end

  describe '#update_max' do
    let(:member_count) { 5 }
    let(:views) { 25_000 }
    let(:founded) { 2.years.ago.to_date }
    let(:decimal) { 3.1415 }

    let!(:band) do
      Band.create!(
        member_count: member_count,
        founded: founded,
        views: views)
    end

    let(:criteria) { Band.all }
    let(:context) { Mongoid::Contextual::Mongo.new(criteria) }

    shared_examples_for 'a max-able context' do
      it 'chooses the larger value' do
        context.update_max("member_count" => given_members, views: given_views)
        expect(band.reload.member_count).to be == [ member_count, given_members ].max
        expect(band.views).to be == [ views, given_views ].max
      end
    end

    context 'when given value < existing value' do
      let(:given_views) { views - 1 }
      let(:given_members) { member_count - 1 }

      it_behaves_like 'a max-able context'
    end

    context 'when given value == existing value' do
      let(:given_views) { views }
      let(:given_members) { member_count }

      it_behaves_like 'a max-able context'
    end

    context 'when given value > existing value' do
      let(:given_views) { views + 1 }
      let(:given_members) { member_count + 1 }

      it_behaves_like 'a max-able context'
    end

    context 'when the named field does not yet exist on the document' do
      it 'sets the field to the argument' do
        context.update_max(new_field: 100)
        expect(band.reload.new_field).to be == 100
      end
    end

    context 'when arguments are dates/times' do
      it 'picks the earliest date' do
        context.update_max(founded: founded + 1)
        expect(band.reload.founded).to be == founded + 1
      end
    end
  end
end
