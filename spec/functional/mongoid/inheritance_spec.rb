require "spec_helper"

describe Mongoid::Document do

  # @todo Durran: Rewrite this ugly-ass spec.

  before do
    [ Browser, Firefox, Canvas ].each(&:delete_all)
  end

  context "when the document is a subclass of a root class" do

    let!(:browser) do
      Browser.create(:version => 3, :name => "Test")
    end

    let(:collection) do
      Mongoid.master.collection("canvases")
    end

    let(:attributes) do
      collection.find({ :name => "Test"}, {}).next_document
    end

    it "persists the versions" do
      attributes["version"].should == 3
    end

    it "persists the type" do
      attributes["_type"].should == "Browser"
    end

    it "persists the attributes" do
      attributes["name"].should == "Test"
    end
  end

  context "when the document is a subclass of a subclass" do

    let!(:firefox) do
      Firefox.create(:version => 2, :name => "Testy")
    end

    let(:collection) do
      Mongoid.master.collection("canvases")
    end

    let(:attributes) do
      collection.find({ :name => "Testy"}, {}).next_document
    end

    before do
      Browser.create(:name => 'Safari', :version => '4.0.0')
    end

    it "persists the versions" do
      attributes["version"].should == 2
    end

    it "persists the type" do
      attributes["_type"].should == "Firefox"
    end

    it "persists the attributes" do
      attributes["name"].should == "Testy"
    end

    it "returns the document when querying for superclass" do
      Browser.where(:name => "Testy").first.should == firefox
    end

    it "returns the document when querying for root class" do
      Canvas.where(:name => "Testy").first.should == firefox
    end

    it 'should returns on of this subclasses if you find by _type' do
      Canvas.where(:_type.in => ['Firefox']).count.should == 1
    end
  end

  context "when the document has associations" do

    let!(:firefox) do
      Firefox.create(:name => "firefox")
    end

    let!(:writer) do
      HtmlWriter.new(:speed => 100)
    end

    let!(:circle) do
      Circle.new(:radius => 50)
    end

    let!(:square) do
      Square.new(:width => 300, :height => 150)
    end

    let(:from_db) do
      Firefox.find(firefox.id)
    end

    before do
      firefox.writer = writer
      firefox.shapes << [ circle, square ]
      firefox.save!
    end

    it "properly persists the one-to-one type" do
      from_db.should be_a_kind_of(Firefox)
    end

    it "properly persists the one-to-one relations" do
      from_db.writer.should == writer
    end

    it "properly persists the one-to-many type" do
      from_db.shapes.first.should == circle
    end

    it "properly persists the one-to-many relations" do
      from_db.shapes.last.should == square
    end

    it "properly sets up the parent relation" do
      from_db.shapes.first.should == circle
    end

    it "properly sets up the entire hierarchy" do
      from_db.shapes.first.canvas.should == firefox
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
      @canvas = Canvas.create(:name => "canvas")
      @canvas.create_palette({})
      @canvas.palette.tools << Pencil.new
      @canvas.palette.tools << Eraser.new
    end

    after do
      Canvas.delete_all
    end

    it "properly saves the subclasses" do
      from_db = Canvas.find(@canvas.id)
      from_db.palette.tools.map(&:class).should == [Pencil, Eraser]
    end
  end

  context "Creating references_many documents from a parent association" do

    before do
      @container = ShippingContainer.create
    end

    it "should allow STI from << using model.new" do
      @container.vehicles << Car.new({})
      @container.vehicles << Truck.new({})
      @container.vehicles.map(&:class).should == [Car,Truck]
    end

    it "should allow STI from << using model.create" do
      @container.vehicles << Car.create({})
      @container.vehicles << Truck.create({})
      @container.vehicles.map(&:class).should == [Car,Truck]
    end

    it "should allow STI from the build call" do
      car = @container.vehicles.build({},Car)
      car.save

      truck = @container.vehicles.build({},Truck)
      truck.save

      @container.vehicles.map(&:class).should == [Car,Truck]
    end

    it "should allow STI from the build call" do
      @container.vehicles.create({},Car)
      @container.vehicles.create({},Truck)
      @container.vehicles.map(&:class).should == [Car,Truck]
    end
  end
end
