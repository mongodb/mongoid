require "spec_helper"

describe Mongoid::Relations::Embedded::Many do

  let(:binding_klass) do
    Mongoid::Relations::Bindings::Embedded::Many
  end

  let(:builder_klass) do
    Mongoid::Relations::Builders::Embedded::Many
  end

  let(:nested_builder_klass) do
    Mongoid::Relations::Builders::NestedAttributes::Many
  end

  let(:binding) do
    stub
  end

  let(:base) do
    Person.new
  end

  let(:address) do
    Address.new
  end

  let(:target) do
    [ address ]
  end

  let(:metadata) do
    Person.relations["addresses"]
  end

  [ :<<, :push, :concat ].each do |method|

    describe "##{method}" do

      let(:relation) do
        described_class.new(base, target, metadata)
      end

      let(:document) do
        Address.new(:street => "Bond St")
      end

      before do
        relation.loaded = true
        binding_klass.expects(:new).returns(binding)
        binding.expects(:bind_one)
      end

      context "when the base is persisted" do

        before do
          base.expects(:persisted?).returns(true)
          document.expects(:save).returns(true)
          relation.send(method, document)
        end

        it "appends the document to the target" do
          relation.target.size.should == 2
        end

        it "adds the metadata to the target" do
          document.metadata.should == metadata
        end

        it "indexes the target" do
          document._index.should == 1
        end
      end

      context "when the base is not persisted" do

        it "does not save the target" do
          document.expects(:save).never
          relation.send(method, document)
        end
      end
    end
  end

  describe "#build" do

    let(:relation) do
      described_class.new(base, target, metadata)
    end

    let!(:document) do
      relation.build(:street => "Picadilly Circus")
    end

    it "appends a new document to the target" do
      relation.size.should == 2
    end

    it "identifies the document" do
      document.id.should == "picadilly-circus"
    end

    it "indexes the document" do
      document._index.should == 1
    end

    it "sets the parent on the document" do
      document._parent.should == base
    end

    it "sets the metadata on the document" do
      document.metadata.should == metadata
    end
  end

  describe "#blank?" do

    let(:relation) do
      described_class.new(base, target, metadata)
    end

    context "when the relation contains elements" do

      it "returns false" do
        relation.should_not be_blank
      end
    end

    context "when the relation contains no elements" do

      before do
        relation.target = []
      end

      it "returns true" do
        relation.should be_blank
      end
    end
  end

  describe ".builder" do

    let(:relation) do
      described_class.new(base, target, metadata)
    end

    let(:document) do
      Address.new
    end

    it "returns the many builder" do
      described_class.builder(metadata, document).should
        be_a(Mongoid::Relations::Builders::Embedded::Many)
    end
  end

  describe "#count" do

    let(:relation) do
      described_class.new(base, target, metadata)
    end

    before do
      address.expects(:persisted?).returns(true)
    end

    it "returns the number of persisted documents" do
      relation.count.should == 1
    end
  end

  describe "#create" do

    let(:relation) do
      described_class.new(base, target, metadata)
    end

    it "builds and saves a new document" do
      Address.any_instance.expects(:save).returns(true)
      relation.create(:street => "Hachiko").street.should == "Hachiko"
    end
  end

  describe "#create!" do

    let(:relation) do
      described_class.new(base, target, metadata)
    end

    context "when validation passes" do

      before do
        Address.any_instance.expects(:save!)
      end

      it "builds and saves a new document" do
        relation.create!(:street => "Hachiko").street.should == "Hachiko"
      end
    end

    context "when validation fails" do

      before do
        Address.any_instance.expects(:save!).raises(
          Mongoid::Errors::Validations.new(address)
        )
      end

      it "raises an error" do
        expect { relation.create! }.to raise_error(Mongoid::Errors::Validations)
      end
    end
  end

  describe "#delete" do

    let(:relation) do
      described_class.new(base, target, metadata)
    end

    context "when the document is in the target" do

      let!(:document) do
        relation.build(:street => "Nan Jing Dong Lu")
      end

      let!(:matching) do
        relation.delete(address)
      end

      it "removes the document from the target" do
        relation.size.should == 1
      end

      it "reindexes the target" do
        document._index.should == 0
      end

      it "returns the matching document" do
        matching.should == address
      end
    end

    context "when the document is not in the target" do

      it "returns nil" do
        relation.delete(Address.new).should be_nil
      end
    end
  end

  [ :delete_all, :destroy_all ].each do |method|

    let(:relation) do
      described_class.new(base, target, metadata)
    end

    describe "##{method}" do

      let!(:document) do
        relation.build(:street => "Folsom")
      end

      let!(:document_two) do
        relation.build(:street => "Harrison")
      end

      context "when conditions are provided" do

        before do
          name = method.to_s.gsub("_all", "")
          document.expects(name)
          relation.send(method, :conditions => { :street => "Folsom" })
        end

        it "removes the matching documents" do
          relation.should == [ address, document_two ]
        end

        it "reindexes the target" do
          document_two._index.should == 1
        end
      end

      context "when no conditions are provided" do

        before do
          name = method.to_s.gsub("_all", "")
          [ address, document, document_two ].each do |doc|
            doc.expects(name)
          end
          relation.send(method)
        end

        it "removes all documents" do
          relation.should == []
        end
      end
    end
  end

  describe ".embedded?" do

    it "returns true" do
      described_class.should be_embedded
    end
  end

  describe "#find" do

    let(:relation) do
      described_class.new(base, [], metadata)
    end

    let!(:address_one) do
      relation.build(:street => "Bond", :city => "London")
    end

    let!(:address_two) do
      relation.build(:street => "Upper", :city => "London")
    end

    context "when providing an id" do

      context "when the id matches" do

        let(:address) do
          relation.find(address_one.id)
        end

        it "returns the matching document" do
          address.should == address_one
        end
      end

      context "when the id does not match" do

        context "when config set to raise error" do

          before do
            Mongoid.raise_not_found_error = true
          end

          it "raises an error" do
            expect {
              relation.find(BSON::ObjectId.new)
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end

        context "when config set not to raise error" do

          let(:address) do
            relation.find(BSON::ObjectId.new)
          end

          before do
            Mongoid.raise_not_found_error = false
          end

          after do
            Mongoid.raise_not_found_error = true
          end

          it "returns nil" do
            address.should be_nil
          end
        end
      end
    end

    context "when providing an array of ids" do

      context "when the ids match" do

        let(:addresses) do
          relation.find([ address_one.id, address_two.id ])
        end

        it "returns the matching documents" do
          addresses.should == [ address_one, address_two ]
        end
      end

      context "when the ids do not match" do

        context "when config set to raise error" do

          before do
            Mongoid.raise_not_found_error = true
          end

          it "raises an error" do
            expect {
              relation.find([ BSON::ObjectId.new ])
            }.to raise_error(Mongoid::Errors::DocumentNotFound)
          end
        end

        context "when config set not to raise error" do

          let(:addresses) do
            relation.find([ BSON::ObjectId.new ])
          end

          before do
            Mongoid.raise_not_found_error = false
          end

          after do
            Mongoid.raise_not_found_error = true
          end

          it "returns an empty array" do
            addresses.should be_empty
          end
        end
      end
    end

    context "when finding first" do

      context "when there is a match" do

        let(:address) do
          relation.find(:first, :conditions => { :city => "London" })
        end

        it "returns the first matching document" do
          address.should == address_one
        end
      end

      context "when there is no match" do

        let(:address) do
          relation.find(:first, :conditions => { :city => "Praha" })
        end

        it "returns nil" do
          address.should be_nil
        end
      end
    end

    context "when finding last" do

      context "when there is a match" do

        let(:address) do
          relation.find(:last, :conditions => { :city => "London" })
        end

        it "returns the last matching document" do
          address.should == address_two
        end
      end

      context "when there is no match" do

        let(:address) do
          relation.find(:last, :conditions => { :city => "Praha" })
        end

        it "returns nil" do
          address.should be_nil
        end
      end
    end

    context "when finding all" do

      context "when there is a match" do

        let(:addresses) do
          relation.find(:all, :conditions => { :city => "London" })
        end

        it "returns the matching documents" do
          addresses.should == [ address_one, address_two ]
        end
      end

      context "when there is no match" do

        let(:address) do
          relation.find(:all, :conditions => { :city => "Praha" })
        end

        it "returns an empty array" do
          address.should be_empty
        end
      end
    end
  end

  describe "#find_or_create_by" do

    let(:relation) do
      described_class.new(base, [], metadata)
    end

    context "when the document exists" do

      let!(:document) do
        relation.build(:street => "Upper St")
      end

      let(:matching) do
        relation.find_or_create_by(:street => "Upper St")
      end

      it "returns the document" do
        matching.should == document
      end
    end

    context "when the document does not exist" do

      let(:new_document) do
        relation.find_or_create_by(:street => "Upper St")
      end

      before do
        Address.any_instance.expects(:save)
      end

      it "creates the document" do
        new_document.street.should == "Upper St"
      end
    end
  end

  describe "#find_or_initialize_by" do

    let(:relation) do
      described_class.new(base, [], metadata)
    end

    context "when the document exists" do

      let!(:document) do
        relation.build(:street => "Upper St")
      end

      let(:matching) do
        relation.find_or_initialize_by(:street => "Upper St")
      end

      it "returns the document" do
        matching.should == document
      end
    end

    context "when the document does not exist" do

      let(:new_document) do
        relation.find_or_initialize_by(:street => "Upper St")
      end

      it "returns a new document" do
        new_document.street.should == "Upper St"
      end
    end
  end

  describe ".macro" do

    it "returns embeds_many" do
      described_class.macro.should == :embeds_many
    end
  end

  describe ".nested_builder" do

    it "returns the many nested builder class" do
      described_class.nested_builder(metadata, {}, {}).should
        be_a(Mongoid::Relations::Builders::NestedAttributes::Many)
    end
  end

  describe "#as_document" do

    it "returns an array of document hashes" do
      relation.as_document.should == [ { "_id" => address.id } ]
    end
  end

  describe ".valid_options" do

    it "returns the valid options" do
      described_class.valid_options.should ==
        [ :as, :cyclic, :order, :versioned ]
    end
  end

  describe "#respond_to?" do

    let(:person) do
      Person.new
    end

    let(:addresses) do
      person.addresses
    end

    Array.public_instance_methods.each do |method|

      context "when checking #{method}" do

        it "returns true" do
          addresses.respond_to?(method).should be_true
        end
      end
    end

    Mongoid::Relations::Embedded::Many.public_instance_methods.each do |method|

      context "when checking #{method}" do

        it "returns true" do
          addresses.respond_to?(method).should be_true
        end
      end
    end

    Address.scopes.keys.each do |method|

      context "when checking #{method}" do

        it "returns true" do
          addresses.respond_to?(method).should be_true
        end
      end
    end

    it "supports 'include_private = boolean'" do
      expect { addresses.respond_to?(:Rational, true) }.not_to raise_error
    end
  end

  describe ".validation_default" do

    it "returns true" do
      described_class.validation_default.should eq(true)
    end
  end
end
