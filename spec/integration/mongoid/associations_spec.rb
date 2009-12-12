require "spec_helper"

describe Mongoid::Associations do

  before do
    Person.delete_all; Game.delete_all; Post.delete_all
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

  end

  context "one-to_many relational associations" do

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

end
