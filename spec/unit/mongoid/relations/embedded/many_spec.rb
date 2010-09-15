require "spec_helper"

describe Mongoid::Relations::Embedded::Many do

  let(:klass) do
    Mongoid::Relations::Embedded::Many
  end

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
    Mongoid::Relations::Metadata.new(
      :relation => klass,
      :inverse_class_name => "Person",
      :name => :addresses,
      :as => :addressable
    )
  end

  [ :<<, :push, :concat ].each do |method|

    describe "##{method}" do

      let(:relation) do
        klass.new(base, target, metadata)
      end

      let(:document) do
        Address.new(:street => "Bond St")
      end

      before do
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

  describe "#bind" do

    let(:relation) do
      klass.new(base, target, metadata)
    end

    before do
      binding_klass.expects(:new).returns(binding)
      binding.expects(:bind_all)
    end

    context "when building" do

      it "does not save the target docs" do
        address.expects(:save).never
        relation.bind(true)
      end
    end

    context "when not building" do

      context "when the base is persisted" do

        before do
          base.expects(:persisted?).returns(true)
        end

        it "saves all target docs" do
          address.expects(:save).returns(true)
          relation.bind
        end
      end

      context "when the base is not persisted" do

        it "does not save any docs" do
          address.expects(:save).never
          relation.bind
        end
      end
    end
  end

  describe "#bind_one" do

    let(:relation) do
      klass.new(base, target, metadata)
    end

    let(:document) do
      Address.new
    end

    before do
      binding_klass.expects(:new).returns(binding)
    end

    it "binds the document" do
      binding.expects(:bind_one).with(document)
      relation.bind_one(document)
    end
  end

  describe "#build" do

    let(:relation) do
      klass.new(base, target, metadata)
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

  describe ".builder" do

    let(:relation) do
      klass.new(base, target, metadata)
    end

    let(:document) do
      Address.new
    end

    it "returns the many builder" do
      klass.builder(metadata, document).should
        be_a(Mongoid::Relations::Builders::Embedded::Many)
    end
  end

  describe "#count" do

    let(:relation) do
      klass.new(base, target, metadata)
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
      klass.new(base, target, metadata)
    end

    it "builds and saves a new document" do
      Address.any_instance.expects(:save).returns(true)
      relation.create(:street => "Hachiko").street.should == "Hachiko"
    end
  end

  describe "#create!" do

    let(:relation) do
      klass.new(base, target, metadata)
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
      klass.new(base, target, metadata)
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
      klass.new(base, target, metadata)
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
      klass.should be_embedded
    end
  end

  describe "#find" do

    let(:relation) do
      klass.new(base, [], metadata)
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

          after do
            Mongoid.raise_not_found_error = false
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

          after do
            Mongoid.raise_not_found_error = false
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
  end

  describe "#find_or_initialize_by" do
  end

  describe ".macro" do

    it "returns embeds_many" do
      klass.macro.should == :embeds_many
    end
  end

  describe ".nested_builder" do

    it "returns the many nested builder class" do
      klass.nested_builder(metadata, {}, {}).should
        be_a(Mongoid::Relations::Builders::NestedAttributes::Many)
    end
  end

  describe "#paginate" do
  end

  describe "#substitute" do
  end

  describe "#to_hash" do

    it "returns an array of document hashes" do
      relation.to_hash.should == [ { "_id" => address.id } ]
    end
  end

  describe "#unbind" do
  end
end
