require "spec_helper"

describe Mongoid::Relations::Builders do

  describe "#build_#\{name}" do

    let(:person) do
      Person.new
    end

    context "when providing no attributes" do

      context "when the relation is an embeds one" do

        let(:name) do
          person.build_name
        end

        it "does not set a binding attribute" do
          name[:binding].should be_nil
        end
      end

      context "when the relation is a references one" do

        let(:game) do
          person.build_game
        end

        it "does not set a binding attribute" do
          game[:binding].should be_nil
        end
      end
    end
  end

  describe "#create_#\{name}" do

    let(:person) do
      Person.new
    end

    context "when providing no attributes" do

      context "when the relation is an embeds one" do

        let(:name) do
          person.create_name
        end

        it "does not set a binding attribute" do
          name[:binding].should be_nil
        end
      end

      context "when the relation is a references one" do

        let(:game) do
          person.create_game
        end

        it "does not set a binding attribute" do
          game[:binding].should be_nil
        end
      end
    end
  end
end
