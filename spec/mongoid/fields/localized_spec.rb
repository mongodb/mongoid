require "spec_helper"

describe Mongoid::Fields::Localized do

  context "when no default is provided" do

    let(:field) do
      described_class.new(:description, localize: true, type: String)
    end

    it "defaults to nil" do
      field.default_val.should be_nil
    end
  end

  context "when a default is provided" do

    context "when the type is a string" do

      let(:field) do
        described_class.new(
          :description,
          localize: true,
          default: "No translation",
          type: String
        )
      end

      it "defaults to the value" do
        field.default_val.should eq("No translation")
      end
    end

    context "when the type is not a string" do

      let(:field) do
        described_class.new(
          :description,
          localize: true,
          default: 1,
          type: Integer
        )
      end

      it "keeps the default in the proper type" do
        field.default_val.should eq(1)
      end
    end
  end

  describe "#demongoize" do

    context "when the type is a string" do

      let(:field) do
        described_class.new(:description, localize: true, type: String)
      end

      context "when the field is nil" do

        let(:value) do
          field.demongoize(nil)
        end

        it "returns nil" do
          value.should be_nil
        end
      end

      context "when no locale is defined" do

        let(:value) do
          field.demongoize({ "en" => "This is a test" })
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
            field.demongoize({ "de" => "This is a test" })
          end

          it "returns the string from the set locale" do
            value.should eq("This is a test")
          end
        end

        context "when the value does not exist" do

          context "when not using fallbacks" do

            let(:value) do
              field.demongoize({ "en" => "testing" })
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
                  field.demongoize({ "en" => "testing" })
                end

                it "returns the fallback translation" do
                  value.should eq("testing")
                end
              end

              context "when another fallback translation exists" do

                let(:value) do
                  field.demongoize({ "es" => "pruebas" })
                end

                it "returns the fallback translation" do
                  value.should eq("pruebas")
                end
              end

              context "when the fallback translation does not exist" do

                let(:value) do
                  field.demongoize({ "fr" => "oui" })
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
                field.demongoize({ "es" => "pruebas" })
              end

              it "returns nil" do
                value.should be_nil
              end
            end
          end
        end
      end
    end

    context "when the type is not a string" do

      let(:field) do
        described_class.new(:description, localize: true, type: Integer)
      end

      context "when the field is nil" do

        let(:value) do
          field.demongoize(nil)
        end

        it "returns nil" do
          value.should be_nil
        end
      end

      context "when no locale is defined" do

        let(:value) do
          field.demongoize({ "en" => 100 })
        end

        it "returns the value from the default locale" do
          value.should eq(100)
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
            field.demongoize({ "de" => 100 })
          end

          it "returns the value from the set locale" do
            value.should eq(100)
          end
        end

        context "when the value does not exist" do

          context "when not using fallbacks" do

            let(:value) do
              field.demongoize({ "en" => 100 })
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
                  field.demongoize({ "en" => 1 })
                end

                it "returns the fallback translation" do
                  value.should eq(1)
                end
              end

              context "when another fallback translation exists" do

                let(:value) do
                  field.demongoize({ "es" => 100 })
                end

                it "returns the fallback translation" do
                  value.should eq(100)
                end
              end

              context "when the fallback translation does not exist" do

                let(:value) do
                  field.demongoize({ "fr" => 50 })
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
                field.demongoize({ "es" => 100 })
              end

              it "returns nil" do
                value.should be_nil
              end
            end
          end
        end
      end
    end
  end

  describe "#mongoize" do

    context "when the type is a string" do

      let(:field) do
        described_class.new(:description, localize: true, type: String)
      end

      context "when no locale is defined" do

        let(:value) do
          field.mongoize("This is a test")
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
          field.mongoize("This is a test")
        end

        it "returns the string in the set locale" do
          value.should eq({ "de" => "This is a test" })
        end
      end
    end

    context "when the type is not a string" do

      let(:field) do
        described_class.new(:description, localize: true, type: Integer)
      end

      context "when no locale is defined" do

        let(:value) do
          field.mongoize("100")
        end

        it "returns the value in the default locale" do
          value.should eq({ "en" => 100 })
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
          field.mongoize("100")
        end

        it "returns the string in the set locale" do
          value.should eq({ "de" => 100 })
        end
      end
    end
  end
end
