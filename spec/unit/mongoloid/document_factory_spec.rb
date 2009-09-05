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

  end

end