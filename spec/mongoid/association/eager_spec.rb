# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Association::EagerLoadable do

  describe ".preload" do

    let(:criteria) do
      Account.where(name: 'savings')
    end

    let(:context) do
      Mongoid::Contextual::Mongo.new(criteria)
    end

    let(:inclusions) do
      includes.map do |key|
        Account.reflect_on_association(key)
      end
    end

    let(:doc) { criteria.first }

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
        expect(doc.ivar(:person)).to eq(doc.person)
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
  end
end
