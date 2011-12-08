require "spec_helper"

describe Mongoid::Fields::Internal::Localized do

  let(:field) do
    described_class.instantiate(:description, :localize => true)
  end

  context "when no default is provided" do

    it "defaults to nil" do
      field.default.should be_nil
    end
  end

  context "when a default is provided" do

    let(:field) do
      described_class.instantiate(
        :description,
        :localize => true,
        :default => "No translation"
      )
    end

    it "defaults to the value" do
      field.default.should eq("No translation")
    end
  end

  describe "#deserialize" do

    context "when no locale is defined" do

      let(:value) do
        field.deserialize({ "en" => "This is a test" })
      end

      it "returns the string from the default locale" do
        value.should eq("This is a test")
      end
    end

    context "when a locale is provided" do

      before do
        ::I18n.locale = :de
      end

      after do
        ::I18n.locale = :en
      end

      context "when the value exists" do

        let(:value) do
          field.deserialize({ "de" => "This is a test" })
        end

        it "returns the string from the set locale" do
          value.should eq("This is a test")
        end
      end

      context "when the value does not exist" do

        context "when not using fallbacks" do

          let(:value) do
            field.deserialize({ "en" => "testing" })
          end

          it "returns nil" do
            value.should be_nil
          end
        end

        context "when using fallbacks" do

          before(:all) do
            require "i18n/backend/fallbacks"
            I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
          end

          context "when fallbacks are defined" do

            before do
              ::I18n.fallbacks[:de] = [ :de, :en, :es ]
            end

            context "when the first fallback translation exists" do

              let(:value) do
                field.deserialize({ "en" => "testing" })
              end

              it "returns the fallback translation" do
                value.should eq("testing")
              end
            end

            context "when another fallback translation exists" do

              let(:value) do
                field.deserialize({ "es" => "pruebas" })
              end

              it "returns the fallback translation" do
                value.should eq("pruebas")
              end
            end

            context "when the fallback translation does not exist" do

              let(:value) do
                field.deserialize({ "fr" => "oui" })
              end

              it "returns nil" do
                value.should be_nil
              end
            end
          end

          context "when no fallbacks are defined" do

            before do
              ::I18n.fallbacks[:de] = [ :de ]
            end

            let(:value) do
              field.deserialize({ "es" => "pruebas" })
            end

            it "returns nil" do
              value.should be_nil
            end
          end
        end
      end
    end
  end

  describe "#serialize" do

    context "when no locale is defined" do

      let(:value) do
        field.serialize("This is a test")
      end

      it "returns the string in the default locale" do
        value.should eq({ "en" => "This is a test" })
      end
    end

    context "when a locale is provided" do

      before do
        ::I18n.locale = :de
      end

      after do
        ::I18n.locale = :en
      end

      let(:value) do
        field.serialize("This is a test")
      end

      it "returns the string in the set locale" do
        value.should eq({ "de" => "This is a test" })
      end
    end
  end
end
