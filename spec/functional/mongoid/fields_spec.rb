require "spec_helper"

describe Mongoid::Fields do

  before do
    Product.delete_all
  end

  describe "#\{field}_translations" do

    let(:product) do
      Product.new
    end

    context "when the field is localized" do

      context "when translations exist" do

        before do
          product.description = "test"
          ::I18n.locale = :de
          product.description = "The best"
        end

        after do
          ::I18n.locale = :en
        end

        let(:translations) do
          product.description_translations
        end

        it "returns all the translations" do
          translations.should eq(
            { "en" => "test", "de" => "The best" }
          )
        end
      end

      context "when translations do not exist" do

        context "when no default is provided" do

          it "returns nil" do
            product.description_translations.should be_nil
          end
        end

        context "when a default is provided" do

          it "returns the translations with the default" do
            product.name_translations.should eq(
              { "en" => "no translation" }
            )
          end
        end
      end
    end

    context "when the field is not localized" do

      it "does not respond to the method" do
        product.should_not respond_to(:price_translations)
      end
    end
  end

  describe "#\{field}_translations=" do

    let(:product) do
      Product.new
    end

    context "when the field is localized" do

      let(:translations) do
        { "en" => "test", "de" => "testing" }
      end

      before do
        product.description_translations = translations
      end

      it "sets the raw values of the translations" do
        product.description_translations.should eq(translations)
      end

      context "when saving the new translations" do

        before do
          product.save
        end

        it "persists the changes" do
          product.reload.description_translations.should eq(translations)
        end

        context "when updating the translations" do

          before do
            product.description_translations = { "en" => "overwritten" }
            product.save
          end

          it "persists the changes" do
            product.reload.description_translations.should eq(
              { "en" => "overwritten" }
            )
          end
        end
      end
    end

    context "when the field is not localized" do

      it "does not respond to the method" do
        product.should_not respond_to(:price_translations=)
      end
    end
  end

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

    context "when the field is an array" do

      before do
        product.stores = [ "kadewe", "karstadt" ]
        product.save
      end

      context "when setting the value to nil" do

        before do
          product.stores = nil
          product.save
        end

        it "allows the set" do
          product.stores.should be_nil
        end
      end

      context "when setting any of the values to nil" do

        before do
          product.stores = [ "kadewe", nil ]
          product.save
        end

        it "allows the set of nil values" do
          product.stores.should eq([ "kadewe", nil ])
        end

        it "persists the nil values" do
          product.reload.stores.should eq([ "kadewe", nil ])
        end
      end

      context "when reversing the array values" do

        before do
          product.stores = [ "karstadt", "kadewe" ]
          product.save
        end

        it "reverses the values" do
          product.stores.should eq([ "karstadt", "kadewe" ])
        end

        it "persists the changes" do
          product.reload.stores.should eq([ "karstadt", "kadewe" ])
        end
      end
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

  context "when a setter accesses a field with a default" do

    let(:person) do
      Person.new(:set_on_map_with_default => "testing")
    end

    it "sets the default value pre process" do
      person.map_with_default.should eq({ "key" => "testing" })
    end
  end
end
