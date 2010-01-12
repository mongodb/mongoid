require "spec_helper"

describe Mongoid::Associations do

  before do
    Mongoid.database.collection(:people).drop
    Mongoid.database.collection(:games).drop
    Mongoid.database.collection(:posts).drop
  end

  context "one-to-one relational associations" do

    before do
      @person = Person.new(:title => "Sir")
      @game = Game.new(:score => 1)
      @person.game = @game
      @person.save
    end

    it "sets the association on save" do
      @from_db = Person.find(@person.id)
      @from_db.game.should == @game
    end

    it "sets the reverse association before save" do
      @game.person.should == @person
    end

    it "sets the reverse association after save" do
      @from_db = Game.find(@game.id)
      @game.person.should == @person
    end

  end

  context "one-to-many relational associations" do

    before do
      @person = Person.new(:title => "Sir")
      @post = Post.new(:title => "Testing")
      @person.posts = [@post]
      @person.save
    end

    it "sets the association on save" do
      @from_db = Person.find(@person.id)
      @from_db.posts.should == [@post]
    end

    context "when building" do

      before do
        @person = Person.new(:title => "Mr")
        @post = @person.posts.build(:title => "First")
      end

      it "sets the reverse association" do
        @post.person.should == @person
      end

    end

  end

  context "nested embedded associations" do

    before do
      @person = Person.create(:title => "Mr")
    end

    context "one level nested" do

      before do
        @address = @person.addresses.create(:street => "Oxford St")
        @name = @person.create_name(:first_name => "Gordon")
      end

      it "persists all the associations properly" do
        @name.last_name = "Brown"
        @person.name.last_name.should == "Brown"
      end

    end

    context "multiple levels nested" do

      context "when a has-many to has_one" do

        before do
          @person.phone_numbers.create(:number => "4155551212")
        end

        it "persists all the associations properly" do
          from_db = Person.find(@person.id)
          phone = from_db.phone_numbers.first
          phone.create_country_code(:code => 1)
          from_db.phone_numbers.first.country_code.code.should == 1
        end

      end

      context "when a has-many to has-many" do

        before do
          @address = Address.new(:street => "Upper Street")
          @person.addresses << @address
        end

        it "bubbles the child association up to root" do
          location = Location.new(:name => "Home")
          @address.locations << location
          location.stubs(:valid?).returns(false)
          @person.save
          @person.addresses.first.locations.first.should == location
        end

      end

    end

  end

end
