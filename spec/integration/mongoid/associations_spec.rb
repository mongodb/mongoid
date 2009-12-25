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

    it "sets the reverse association" do
      @from_db = Game.find(@game.id)
      @game.person.should == @person
    end

    context "when the association has not been set" do

      it "returns nil" do
        @game.person_id = "12342314213"
        @game.save
        @from_db = Game.find(@game.id)
        @from_db.person.should be_nil
      end

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

  end

  context "nested embedded associations" do

    before do
      @person = Person.create(:title => "Mr")
    end

    context "one level nested" do

      before do
        @address = @person.addresses.create(:street => "Oxford St")
        @name = @person.name.create(:first_name => "Gordon")
      end

      it "persists all the associations properly" do
        @name.last_name = "Brown"
        @person.name.last_name.should == "Brown"
      end

    end

    context "multiple levels nested" do

      before do
        @person.phone_numbers.create(:number => "4155551212")
      end

      it "persists all the associations properly" do
        from_db = Person.find(@person.id)
        phone = from_db.phone_numbers.first
        phone.country_code.create(:code => 1)
        from_db.phone_numbers.first.country_code.code.should == 1
      end

    end

  end

end
