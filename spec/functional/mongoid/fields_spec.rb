require "spec_helper"

describe Mongoid::Fields do

  describe "#getter" do

    context "when a field is localized" do

      let(:product) do
        Product.new
      end

      context "when no locale is set" do

        before do
          product.description = "The best"
        end

        let(:description) do
          product.description
        end

        it "returns the default locale value" do
          description.should eq("The best")
        end
      end

      context "when a single locale is set" do

        before do
          ::I18n.locale = :de
          product.description = "The best"
        end

        after do
          ::I18n.locale = :en
        end

        let(:description) do
          product.description
        end

        it "returns the set locale value" do
          description.should eq("The best")
        end
      end

      context "when multiple locales are set" do

        before do
          product.description = "Cheap drinks"
          ::I18n.locale = :de
          product.description = "Cheaper drinks"
        end

        after do
          ::I18n.locale = :en
        end

        let(:description) do
          product.description
        end

        it "returns the current locale value" do
          description.should eq("Cheaper drinks")
        end
      end
    end
  end

  describe "#setter=" do

    let(:product) do
      Product.new
    end

    context "when a field is localized" do

      context "when no locale is set" do

        before do
          product.description = "Cheap drinks"
        end

        let(:description) do
          product.attributes["description"]
        end

        it "sets the value in the default locale" do
          description.should eq({ "en" => "Cheap drinks" })
        end
      end

      context "when a locale is set" do

        before do
          ::I18n.locale = :de
          product.description = "Cheaper drinks"
        end

        after do
          ::I18n.locale = :en
        end

        let(:description) do
          product.attributes["description"]
        end

        it "sets the value in the default locale" do
          description.should eq({ "de" => "Cheaper drinks" })
        end
      end

      context "when having multiple locales" do

        before do
          product.description = "Cheap drinks"
          ::I18n.locale = :de
          product.description = "Cheaper drinks"
        end

        after do
          ::I18n.locale = :en
        end

        let(:description) do
          product.attributes["description"]
        end

        it "sets the value in both locales" do
          description.should eq(
            { "de" => "Cheaper drinks", "en" => "Cheap drinks" }
          )
        end
      end
    end
  end
end
