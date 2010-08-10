require "spec_helper"

describe Mongoid::Relations::Embedded::Many do

  let(:klass) do
    Mongoid::Relations::Embedded::Many
  end

  let(:metadata) do
    stub(:name => :addresses, :klass => Address, :extension? => false)
  end

  let(:base) do
    Person.new
  end

  describe "#<<" do

    context "when adding a single document" do

      let(:address) do
        Address.new
      end

      let(:document) do
        address
      end

      let(:relation) do
        klass.new(base, [], metadata)
      end

      before do
        relation << document
      end

      it "adds the parent to the document" do
        address._parent.should == base
      end

      it "appends to the target" do
        relation.target.size.should == 1
      end

      it "sets the index" do
        address._index.should == 0
      end
    end

    context "when adding multiple documents" do

      let(:address) do
        Address.new
      end

      let(:documents) do
        [ address ]
      end

      let(:relation) do
        klass.new(base, [], metadata)
      end

      before do
        relation << documents
      end

      it "adds the parent to the documents" do
        address._parent.should == base
      end

      it "appends to the target" do
        relation.target.size.should == 1
      end

      it "sets the indices" do
        address._index.should == 0
      end
    end
  end

  describe "#build" do

    context "when providing a type" do

      let(:base) do
        Canvas.new
      end

      let(:metadata) do
        stub(:name => :shapes, :klass => Shape, :extension? => false)
      end

      let(:relation) do
        klass.new(base, [], metadata)
      end

      before do
        @shape = relation.build(
          { :radius => 10 },
          Circle
        )
      end

      it "returns a new document" do
        @shape.should be_a_kind_of(Circle)
      end

      it "sets the attributes on the new document" do
        @shape.radius.should == 10
      end

      it "sets the type on the new document" do
        @shape._type.should == "Circle"
      end

      it "adds the parent to the new document" do
        @shape._parent.should == base
      end

      it "appends to the target" do
        relation.target.size.should == 1
      end

      it "sets the indices" do
        @shape._index.should == 0
      end
    end

    context "when not providing a type" do

      let(:relation) do
        klass.new(base, [], metadata)
      end

      before do
        @address = relation.build(:street => "Nan Jing Dong Lu")
      end

      it "returns a new document" do
        @address.should be_a_kind_of(Address)
      end

      it "sets the attributes on the new document" do
        @address.street.should == "Nan Jing Dong Lu"
      end

      it "adds the parent to the new document" do
        @address._parent.should == base
      end

      it "appends to the target" do
        relation.target.size.should == 1
      end

      it "sets the indices" do
        @address._index.should == 0
      end
    end
  end

  describe ".builder" do

    let(:builder_klass) do
      Mongoid::Relations::Builders::Embedded::Many
    end

    let(:document) do
      stub
    end

    let(:metadata) do
      stub(:extension? => false)
    end

    it "returns the embeds many builder" do
      klass.builder(metadata, [ document ]).should
        be_a_kind_of(builder_klass)
    end
  end

  describe "#count" do

    let(:documents) do
      [ stub(:persisted? => true), stub(:persisted? => false) ]
    end

    let(:relation) do
      klass.new(base, documents, metadata)
    end

    it "returns the number of persisted documents" do
      relation.count.should == 1
    end
  end

  describe "#create" do

    context "when a type is provided" do

      let(:base) do
        Canvas.new
      end

      let(:metadata) do
        stub(:name => :shapes, :klass => Shape, :extension? => false)
      end

      let(:relation) do
        klass.new(base, [], metadata)
      end

      let(:circle) do
        Circle.new
      end

      before do
        Circle.expects(:instantiate).returns(circle)
        circle.expects(:save).returns(true)
        @shape = relation.create(
          { :radius => 10 },
          Circle
        )
      end

      it "returns a saved document" do
        @shape.should be_a_kind_of(Circle)
      end
    end

    context "when a type is not provided" do

      let(:relation) do
        klass.new(base, [], metadata)
      end

      let(:address) do
        Address.new
      end

      before do
        Address.expects(:instantiate).returns(address)
        address.expects(:save).returns(true)
        @address = relation.create(:street => "Nan Jing Dong Lu")
      end

      it "returns a saved document" do
        @address.should be_a_kind_of(Address)
      end
    end
  end

  describe "#create!" do

    context "when validation passes" do

      let(:relation) do
        klass.new(base, [], metadata)
      end

      let(:address) do
        Address.new
      end

      before do
        Address.expects(:instantiate).returns(address)
        address.expects(:save).returns(true)
        @address = relation.create!(:street => "Nan Jing Dong Lu")
      end

      it "returns a saved document" do
        @address.should be_a_kind_of(Address)
      end
    end

    context "when validation fails" do

      let(:relation) do
        klass.new(base, [], metadata)
      end

      let(:address) do
        Address.new
      end

      before do
        Address.expects(:instantiate).returns(address)
        address.expects(:save).returns(false)
        address.errors[:street] = [ "is require" ]
      end

      it "raises an error" do
        expect {
          relation.create!(:street => "Nan Jing Dong Lu")
        }.to raise_error(Mongoid::Errors::Validations)
      end
    end
  end

  describe "#delete_all" do

    let(:address) do
      Address.new(:street => "Street 1")
    end

    let(:relation) do
      klass.new(base, [ address ], metadata)
    end

    context "when no conditions passed" do

      before do
        address.expects(:delete)
      end

      it "clears the target" do
        relation.delete_all
        relation.size.should == 0
      end

      it "returns the number of documents deleted" do
        relation.delete_all.should == 1
      end

    end

    context "when conditions passed" do

      before do
        address.expects(:delete)
      end

      it "deletes the correct documents" do
        relation.delete_all(:conditions => { :street => "Street 1" })
        relation.size.should == 0
      end

      it "returns the number of documents deleted" do
        relation.delete_all(
          :conditions => { :street => "Street 1" }
        ).should == 1
      end
    end
  end

  describe "#destroy_all" do

    let(:address) do
      Address.new(:street => "Street 1")
    end

    let(:relation) do
      klass.new(base, [ address ], metadata)
    end

    context "when no conditions passed" do

      before do
        address.expects(:destroy)
      end

      it "clears the target" do
        relation.destroy_all
        relation.size.should == 0
      end

      it "returns the number of documents deleted" do
        relation.destroy_all.should == 1
      end

    end

    context "when conditions passed" do

      before do
        address.expects(:destroy)
      end

      it "deletes the correct documents" do
        relation.destroy_all(:conditions => { :street => "Street 1" })
        relation.size.should == 0
      end

      it "returns the number of documents deleted" do
        relation.destroy_all(
          :conditions => { :street => "Street 1" }
        ).should == 1
      end
    end
  end

  describe "#find" do

    context "when finding all" do

      let(:address) do
        Address.new(:street => "Street 1")
      end

      let(:relation) do
        klass.new(base, [ address ], metadata)
      end

      it "returns all the documents" do
        relation.find(:all).should == relation
      end
    end

    context "when finding by id" do

      context "when using string ids" do

        let(:address) do
          Address.new(:street => "Street 2")
        end

        let(:relation) do
          klass.new(base, [ address ], metadata)
        end

        it "returns the matching document" do
          relation.find("street-2").should == address
        end
      end

      context "when using object ids" do

        let(:favorite) do
          Favorite.new(:title => "Test")
        end

        let(:metadata) do
          stub(:name => :favorites, :klass => Favorite, :extension? => false)
        end

        let(:relation) do
          klass.new(base, [ favorite ], metadata)
        end

        context "when passed an object id" do

          it "finds using the object id" do
            relation.find(favorite.id).should == favorite
          end
        end

        context "when passed a string" do

          it "finds using the object id" do
            relation.find(favorite.id.to_s).should == favorite
          end
        end
      end
    end
  end

  describe ".macro" do

    it "returns :embeds_many" do
      klass.macro.should == :embeds_many
    end
  end

  describe "#method_missing" do

    let(:address) do
      Address.new(:street => "Street 2", :state => "CA")
    end

    let(:relation) do
      klass.new(base, [ address ], metadata)
    end

    before do
      relation << Address.new(:state => "FL")
    end

    context "when the relation has a criteria class method" do

      let(:cali) do
        relation.california
      end

      it "returns the criteria" do
        cali.should be_a_kind_of(Mongoid::Criteria)
      end

      it "sets the documents on the criteria" do
        cali.documents.should == relation.entries
      end

      it "returns the scoped documents" do
        cali.size.should == 1
        cali.first.state.should == "CA"
      end
    end

    context "when calling criteria methods" do

      it "can use fancy criteria clauses" do
        relation.where(:state => /CA/).count.should ==
          relation.where(:state => 'CA').count
      end
    end

    context "when no class method exists" do

      it "delegates to the array" do
        relation.entries.size.should == 2
      end
    end
  end

  describe "#nested_build" do

    it "is horrendous and needs an overhaul"
  end

  describe "#paginate" do

    let(:relation) do
      klass.new(base, [], metadata)
    end

    let(:options) do
      { :page => 1, :per_page => 10 }
    end

    let(:criteria) do
      stub
    end

    before do
      Mongoid::Criteria.expects(:translate).with(
        Address, options
      ).returns(criteria)
      criteria.expects(:documents=).with(relation.target)
      criteria.expects(:paginate).returns([])
    end

    it "creates a criteria and paginates it" do
      relation.paginate(options).should == []
    end
  end

  context "properties" do

    let(:documents) do
      [ stub ]
    end

    let(:relation) do
      klass.new(base, documents, metadata)
    end

    describe "#metadata" do

      it "returns the relation's metadata" do
        relation.metadata.should == metadata
      end
    end

    describe "#target" do

      it "returns the relation's target" do
        relation.target.should == documents
      end
    end
  end

  describe "#substitute" do

    let(:documents) do
      [ stub ]
    end

    let(:relation) do
      klass.new(base, documents, metadata)
    end

    context "when the target is nil" do

      it "clears out the target" do
        relation.substitute(nil)
        relation.target.should == []
      end

      it "returns self" do
        relation.substitute(nil).should == relation
      end
    end

    context "when the target is not nil" do

      let(:new_docs) do
        [ stub ]
      end

      it "replaces the target" do
        relation.substitute(new_docs)
        relation.target.should == new_docs
      end

      it "returns self" do
        relation.substitute(new_docs).should == relation
      end
    end
  end
end
