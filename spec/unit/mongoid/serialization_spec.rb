require "spec_helper"

describe Mongoid::Document do

  describe "#to_json" do

    let(:person) do
      Person.new
    end

    context "when including root in json" do

      before do
        Mongoid.include_root_in_json = true
      end

      it "uses the mongoid configuration" do
        person.to_json.should include("person")
      end
    end

    context "when not including root in json" do

      before do
        Mongoid.include_root_in_json = false
      end

      it "uses the mongoid configuration" do
        person.to_json.should_not include("person")
      end
    end
  end

  describe "#to_xml" do

    context "when an Array field is defined" do

      let(:person) do
        Person.new(
          :aliases => [ "Kelly", "Machine Gun" ]
        )
      end

      it "properly types the array" do
        person.to_xml.should include("<aliases type=\"array\">")
      end

      it "serializes the array" do
        person.to_xml.should include("<alias>Kelly</alias>")
        person.to_xml.should include("<alias>Machine Gun</alias>")
      end
    end

    context "when a Hash field is defined" do

      let(:person) do
        Person.new(
          :map => { :lat => 24.5, :long => 22.1 }
        )
      end

      it "properly types the hash" do
        person.to_xml.should include("<map>")
      end

      it "serializes the hash" do
        person.to_xml.should include("<lat type=\"float\">24.5</lat>")
        person.to_xml.should include("<long type=\"float\">22.1</long>")
      end
    end
  end
end
