require "spec_helper"

describe Mongoid::Document do

  before do
    Browser.delete_all
    Firefox.delete_all
    Canvas.delete_all
  end

  context "when document is a subclass of a root class" do

    before do
      Browser.delete_all
      @browser = Browser.create(:version => 3, :name => "Test")
    end

    it "saves in the same collection as the root" do
      collection = Mongoid.master.collection("canvases")
      attributes = collection.find({ :name => "Test"}, {}).next_document
      attributes["version"].should == 3
      attributes["name"].should == "Test"
      attributes["_type"].should == "Browser"
      attributes["_id"].should == @browser.id
    end

  end

  context "when document is a subclass of a subclass" do

    before do
      Firefox.delete_all
      @firefox = Firefox.create(:version => 2, :name => "Testy")
    end

    it "saves in the same collection as the root" do
      collection = Mongoid.master.collection("canvases")
      attributes = collection.find({ :name => "Testy"}, {}).next_document
      attributes["version"].should == 2
      attributes["name"].should == "Testy"
      attributes["_type"].should == "Firefox"
      attributes["_id"].should == @firefox.id
    end

    it "returns the document when querying for superclass" do
      Browser.where(:name => "Testy").first.should == @firefox
    end

    it "returns the document when querying for root class" do
      Canvas.where(:name => "Testy").first.should == @firefox
    end

  end

  context "when document has associations" do

    before do
      Firefox.delete_all
      @firefox = Firefox.new(:name => "firefox")
      @writer = HtmlWriter.new(:speed => 100)
      @circle = Circle.new(:radius => 50)
      @square = Square.new(:width => 300, :height => 150)
      @firefox.writer = @writer
      @firefox.shapes << [ @circle, @square ]
      @firefox.save!
    end

    after do
      Firefox.delete_all
    end

    it "properly saves a has one subclass" do
      from_db = Firefox.find(@firefox.id)
      from_db.should be_a_kind_of(Firefox)
      from_db.writer.should be_a_kind_of(HtmlWriter)
      from_db.writer.should == @writer
    end

    it "properly saves a has many subclass" do
      from_db = Firefox.find(@firefox.id)
      from_db.shapes.first.should == @circle
      from_db.shapes.first.should be_a_kind_of(Circle)
      from_db.shapes.last.should == @square
      from_db.shapes.last.should be_a_kind_of(Square)
    end

    it "properly sets up the belongs to" do
      from_db = Firefox.find(@firefox.id)
      circle = from_db.shapes.first
      circle.should == @circle
      circle.canvas.should == @firefox
    end

  end

  context "when document has subclasses" do

    before do
      @firefox = Firefox.create(:name => "firefox")
    end

    after do
      Firefox.delete_all
    end

    it "returns subclasses for querying parents" do
      firefox = Canvas.where(:name => "firefox").first
      firefox.should be_a_kind_of(Firefox)
      firefox.should == @firefox
    end

  end

  context "deleting subclasses" do

    before do
      @firefox = Firefox.create(:name => "firefox")
      @firefox2 = Firefox.create(:name => "firefox 2")
      @browser = Browser.create(:name => "browser")
      @canvas = Canvas.create(:name => "canvas")
    end

    after do
      Firefox.delete_all
      Browser.delete_all
      Canvas.delete_all
    end

    it "deletes from the parent class collection" do
      @firefox.delete
      Firefox.count.should == 1
      Browser.count.should == 2
      Canvas.count.should == 3
    end
    
    it "deletes all documents except for those belonging to parent class collection" do
      Firefox.delete_all
      Firefox.count.should == 0
      Browser.count.should == 1
      Canvas.count.should == 2
    end

  end

  context "when document is a subclass and its parent is an embedded document" do

    before do
      @canvas = Canvas.new(:name => "canvas")
      @canvas.build_palette({})
      @canvas.palette.tools << Pencil.new
      @canvas.palette.tools << Eraser.new
      @canvas.save
    end

    after do
      Canvas.delete_all
    end

    it "properly saves the subclasses" do
      from_db = Canvas.find(@canvas.id)
      from_db.palette.tools.map(&:class).should == [Pencil, Eraser]
    end

  end

end
