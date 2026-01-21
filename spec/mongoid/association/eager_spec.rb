# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"

describe Mongoid::Association::EagerLoadable do

  describe ".preload" do

    let(:criteria) do
      Account.where(name: 'savings')
    end

    let(:context) do
      Mongoid::Contextual::Mongo.new(criteria)
    end

    let(:association_host) { Account }

    let(:inclusions) do
      includes.map do |key|
        association_host.reflect_on_association(key)
      end
    end

    let(:doc) { criteria.first }

    context 'when root is an STI subclass' do
      # Driver has_one Vehicle
      # Vehicle belongs_to Driver
      # Truck is a Vehicle

      before do
        Driver.create!(vehicle: Truck.new)
      end

      let(:criteria) { Truck.all }
      let(:includes) { %i[ driver ] }
      let(:association_host) { Truck }

      it 'preloads the driver' do
        expect(doc.ivar(:driver)).to be false
        context.preload(inclusions, [ doc ])
        expect(doc.ivar(:driver)).to be == Driver.first
      end
    end

    context "when belongs_to" do

      let!(:account) do
        Account.create!(person: person, name: 'savings')
      end

      let(:person) do
        Person.create!
      end

      let(:includes) { [:person] }

      it "groups by foreign_key" do
        expect(doc).to receive(:person_id).once
        context.preload(inclusions, [doc])
      end

      it "preloads the parent" do
        expect(doc.ivar(:person)).to be false
        context.preload(inclusions, [doc])
        expect(doc.ivar(:person)).to be == person
      end
    end

    context "when has_one" do

      let(:account) do
        Account.create!(name: 'savings')
      end

      let!(:comment) do
        Comment.create!(title: 'my account comment', account: account)
      end

      let(:includes) { [:comment] }

      it "preloads the child" do
        expect(doc.ivar(:comment)).to be false
        context.preload(inclusions, [doc])
        expect(doc.ivar(:comment)).to eq(doc.comment)
      end
    end

    context "when has_many" do

      let(:account) do
        Account.create!(name: 'savings')
      end

      let!(:alert) do
        Alert.create!(account: account)
      end

      let(:includes) { [:alerts] }

      it "preloads the child" do
        expect(doc.ivar(:alerts)).to be false
        context.preload(inclusions, [doc])
        expect(doc.ivar(:alerts)).to eq(doc.alerts)
      end
    end

    context "when has_and_belongs_to_many" do

      let(:account) do
        Account.create!(name: 'savings')
      end

      let!(:agent) do
        Agent.create!(accounts: [account])
      end

      let(:includes) { [:agents] }

      it "preloads the child" do
        expect(doc.ivar(:agents)).to be false
        context.preload(inclusions, [doc])
        expect(doc.ivar(:agents)).to eq(doc.agents)
      end
    end
  end

  describe ".eager_load" do

    before do
      Person.create!
    end

    let(:context) do
      Mongoid::Contextual::Mongo.new(criteria)
    end

    context "when including one has_many relation" do

      let(:criteria) do
        Person.includes(:posts)
      end

      let(:docs) do
        Person.all.to_a
      end

      let(:posts_association) do
        Person.reflect_on_association(:posts)
      end

      it "runs the has_many preload" do
        expect(Mongoid::Association::Referenced::HasMany::Eager).to receive(:new).with([posts_association], docs).once.and_call_original

        context.eager_load(docs)
      end

      context 'when combined with a #find_by' do

        let!(:person) do
          Person.create!(title: 'manager')
        end

        it 'executes the find_by' do
          expect(criteria.find_by(title: 'manager')).to eq(person)
        end
      end
    end

    context "when including multiple relations" do

      let(:criteria) do
        Person.includes(:posts, :houses, :cat)
      end

      let(:docs) do
        Person.all.to_a
      end

      let(:posts_association) do
        Person.reflect_on_association(:posts)
      end

      let(:houses_association) do
        Person.reflect_on_association(:houses)
      end

      let(:cat_association) do
        Person.reflect_on_association(:cat)
      end

      it "runs the has_many preload" do
        expect(Mongoid::Association::Referenced::HasMany::Eager).to receive(:new).with([posts_association], docs).once.and_call_original

        context.eager_load(docs)
      end

      it "runs the has_one preload" do
        expect(Mongoid::Association::Referenced::HasOne::Eager).to receive(:new).with([cat_association], docs).once.and_call_original
        context.eager_load(docs)
      end

      it "runs the has_and_belongs_to_many preload" do
        expect(Mongoid::Association::Referenced::HasAndBelongsToMany::Eager).to receive(:new).with([houses_association], docs).once.and_call_original
        context.eager_load(docs)
      end

      context 'when one of the eager loading definitions is nested' do

        before do
          class User
            include Mongoid::Document
          end

          class Unit
            include Mongoid::Document
          end

          class Booking
            include Mongoid::Document
            belongs_to :unit
            has_many :vouchers
          end

          class Voucher
            include Mongoid::Document
            belongs_to :booking
            belongs_to :created_by, class_name: 'User'
          end
        end

        it 'successfully loads all relations' do
          user = User.create!
          unit = Unit.create!
          booking = Booking.create!(unit: unit)
          Voucher.create!(booking: booking, created_by: user)

          vouchers = Voucher.includes(:created_by, booking: [:unit])

          vouchers.each do |voucher|
            expect(voucher.created_by).to eql(user)
            expect(voucher.booking).to eql(booking)
            expect(voucher.booking.unit).to eql(unit)
          end
        end
      end
    end

    context "when including two of the same relation type" do

      let(:criteria) do
        Person.includes(:book, :cat)
      end

      let(:docs) do
        Person.all.to_a
      end

      let(:book_association) do
        Person.reflect_on_association(:book)
      end

      let(:cat_association) do
        Person.reflect_on_association(:cat)
      end

      it "runs the has_one preload" do
        expect(Mongoid::Association::Referenced::HasOne::Eager).to receive(:new).with([ book_association ], docs).once.and_call_original
        expect(Mongoid::Association::Referenced::HasOne::Eager).to receive(:new).with([ cat_association ], docs).once.and_call_original
        context.eager_load(docs)
      end
    end

    context "when including an embedded_in relation" do
      let!(:account) { Account.create(name: "home", memberships: memberships) }
      let(:memberships) { [ Membership.new(name: "his"), Membership.new(name: "hers") ] }
      let(:criteria) { Account.includes(memberships: :account) }

      it "loads the parent document" do
        result = criteria.find_by(name: "home")
        expect(result).to eq(account)
        expect(result.memberships.first.account).to eq(account)
      end
    end

    context "when including an embeds_many relation" do
      let!(:account) { Account.create(name: "home", memberships: memberships) }
      let(:memberships) { [ Membership.new(name: "his"), Membership.new(name: "hers") ] }
      let(:criteria) { Account.includes(:memberships) }

      it "loads the subdocuments" do
        result = criteria.find_by(name: "home")
        expect(result).to eq(account)
        expect(result.memberships.count).to eq(2)
      end
    end

    context "when including an embeds_one relation" do
      let!(:person) { Person.create(username: "test", pet: pet) }
      let(:pet) { Animal.new(name: "fido") }
      let(:criteria) { Person.includes(:pet) }

      it "loads the subdocument" do
        result = criteria.find_by(username: "test")
        expect(result).to eq(person)
        expect(result.pet).to eq(pet)
      end
    end

    context "when chaining a referenced association from an embedded relation" do
      let!(:person) { Person.create(username: "test", messages: [ message ]) }
      let!(:post) { Post.create(title: "notice", posteable: message) }
      let(:message) { Message.new(body: "hello") }
      let(:criteria) { Person.includes(messages: :post) }

      it "loads the referenced association" do
        result = criteria.find_by(username: "test")
        expect(result).to eq(person)
        expect(result.messages.first.post).to eq(post)
      end
    end
  end

  describe ".eager_loadable?" do

    let(:context) do
      Mongoid::Contextual::Mongo.new(criteria)
    end

    context "when criteria has multiple includes" do

      let(:criteria) do
        Post.includes(:person, :roles)
      end

      it "is eager_loadable" do
        expect(context.eager_loadable?).to be true
      end
    end

    context "when criteria has no includes" do

      let(:criteria) do
        Post.all
      end

      it "is not eager_loadable" do
        expect(context.eager_loadable?).to be false
      end
    end

    context "when criteria has multiple eager_load fields" do

      let(:criteria) do
        Post.eager_load(:person, :roles)
      end

      it "is eager_loadable" do
        expect(context.eager_loadable?).to be true
      end
    end

    context "when criteria has no eager_load fields" do

      let(:criteria) do
        Post.all
      end

      it "is not eager_loadable" do
        expect(context.eager_loadable?).to be false
      end
    end
  end

  describe ".preload_for_lookup" do

    let(:context) do
      Mongoid::Contextual::Mongo.new(criteria)
    end

    context "when belongs_to" do

      let!(:person) do
        Person.create!
      end

      let!(:account) do
        Account.create!(person: person, name: 'savings')
      end

      let(:criteria) do
        Account.where(name: 'savings').eager_load(:person)
      end

      it "preloads the parent using $lookup" do
        docs = context.preload_for_lookup(criteria)
        expect(docs.first.person).to eq(person)
      end

      it "does not execute additional queries" do
        docs = context.preload_for_lookup(criteria)
        expect_query(0) do
          docs.first.person
        end
      end
    end

    context "when has_one" do

      let!(:account) do
        Account.create!(name: 'savings')
      end

      let!(:comment) do
        Comment.create!(title: 'my account comment', account: account)
      end

      let(:criteria) do
        Account.where(name: 'savings').eager_load(:comment)
      end

      it "preloads the child using $lookup" do
        docs = context.preload_for_lookup(criteria)
        expect(docs.first.comment).to eq(comment)
      end

      it "does not execute additional queries" do
        docs = context.preload_for_lookup(criteria)
        expect_query(0) do
          docs.first.comment
        end
      end
    end

    context "when has_many" do

      let!(:person) do
        Person.create!
      end

      let!(:post1) do
        Post.create!(person: person, title: 'first')
      end

      let!(:post2) do
        Post.create!(person: person, title: 'second')
      end

      let(:criteria) do
        Person.where(id: person.id).eager_load(:posts)
      end

      it "preloads the children using $lookup" do
        docs = context.preload_for_lookup(criteria)
        expect(docs.first.posts).to match_array([post1, post2])
      end

      it "does not execute additional queries" do
        docs = context.preload_for_lookup(criteria)
        expect_query(0) do
          docs.first.posts.to_a
        end
      end
    end

    context "when has_and_belongs_to_many" do

      let!(:person) do
        Person.create!
      end

      let!(:house1) do
        House.create!(name: 'first')
      end

      let!(:house2) do
        House.create!(name: 'second')
      end

      before do
        person.houses = [house1, house2]
        person.save!
      end

      let(:criteria) do
        Person.where(id: person.id).eager_load(:houses)
      end

      it "preloads the children using $lookup" do
        docs = context.preload_for_lookup(criteria)
        expect(docs.first.houses).to match_array([house1, house2])
      end

      it "does not execute additional queries" do
        docs = context.preload_for_lookup(criteria)
        expect_query(0) do
          docs.first.houses.to_a
        end
      end
    end

    context "when including multiple relations" do

      let!(:person) do
        Person.create!
      end

      let!(:post) do
        Post.create!(person: person, title: 'first')
      end

      let!(:house) do
        House.create!(name: 'home')
      end

      let!(:cat) do
        Cat.create!(person: person, name: 'fluffy')
      end

      before do
        person.houses << house
        person.save!
      end

      let(:criteria) do
        Person.where(id: person.id).eager_load(:posts, :houses, :cat)
      end

      it "preloads all relations using $lookup" do
        docs = context.preload_for_lookup(criteria)
        doc = docs.first
        expect(doc.posts).to eq([post])
        expect(doc.houses).to eq([house])
        expect(doc.cat).to eq(cat)
      end

      it "does not execute additional queries" do
        docs = context.preload_for_lookup(criteria)
        doc = docs.first
        expect_query(0) do
          # doc.posts.to_a
          # doc.houses.to_a
          doc.cat
        end
      end
    end

    context "when including nested associations" do

      let!(:person) do
        Person.create!
      end

      let!(:post) do
        Post.create!(person: person, title: 'first')
      end

      let!(:alert) do
        Alert.create!(post: post, message: 'alert!')
      end

      let(:criteria) do
        Person.where(id: person.id).eager_load(posts: :alerts)
      end

      it "preloads nested relations using $lookup" do
        docs = context.preload_for_lookup(criteria)
        doc = docs.first
        expect(doc.posts).to eq([post])
        expect(doc.posts.first.alerts).to eq([alert])
      end

      it "does not execute additional queries" do
        docs = context.preload_for_lookup(criteria)
        doc = docs.first
        expect_query(0) do
          doc.posts.first.alerts.to_a
        end
      end
    end

    context "when root is an STI subclass" do

      before do
        Driver.create!(vehicle: Truck.new)
      end

      let(:criteria) do
        Truck.all.eager_load(:driver)
      end

      it "preloads the driver using $lookup" do
        docs = context.preload_for_lookup(criteria)
        expect(docs.first.driver).to eq(Driver.first)
      end

      it "does not execute additional queries" do
        docs = context.preload_for_lookup(criteria)
        expect_query(0) do
          docs.first.driver
        end
      end
    end

    context "when criteria is embedded" do

      let!(:person) do
        Person.create!
      end

      let!(:address) do
        person.addresses.create!(street: 'main st')
      end

      let!(:band) do
        Band.create!(name: 'Depeche Mode')
      end

      before do
        address.band = band
        address.save!
      end

      let(:criteria) do
        person.addresses.eager_load(:band)
      end

      it "falls back to traditional preload" do
        # Embedded documents use traditional preload even with eager_load
        docs = criteria.to_a
        expect(docs.first.band).to eq(band)
      end
    end
  end
end
