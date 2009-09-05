require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

describe Mongoloid::DocumentFactory do

  describe "#create" do

    context "with no nested attributes" do

      before do
        @attributes = { :title => "Consigliare", :document_class => "Person" }
      end

      it "instantiates a new Document" do
        document = Mongoloid::DocumentFactory.create(@attributes)
        document.should be_a_kind_of(Person)
      end

      it "sets the Document attributes" do
        document = Mongoloid::DocumentFactory.create(@attributes)
        document.title.should == @attributes[:title]
      end

    end

    context "with a has_one association" do

      before do
        @attributes = { :title => "Consigliare", :document_class => "Person", 
                        :name => { :first_name => "Robin", :last_name => "Williams", :document_class => "Name" } }
      end

      it "sets the associations" do
        person = Mongoloid::DocumentFactory.create(@attributes)
        person.name.first_name.should == "Robin"
      end

    end

    context "with has_one and has_many associations" do

      before do
        @attributes = { :title => "Consigliare", :document_class => "Person", 
                        :name => { :first_name => "Robin", :last_name => "Williams", :document_class => "Name" }, 
                        :addresses => [ { :street => "38 Genoa Place", :city => "San Francisco", :state => "CA", :post_code => "94133", :document_class => "Address" },
                                        { :street => "668 Bourke Street", :city => "Melbourne", :state => "VIC", :post_code => "3000", :document_class => "Address" } ] }
      end

      it "sets the associations" do
        person = Mongoloid::DocumentFactory.create(@attributes)
        person.name.first_name.should == "Robin"
        person.addresses[0].street.should == "38 Genoa Place"
        person.addresses[1].street.should == "668 Bourke Street"
      end

    end

  end

end