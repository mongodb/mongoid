# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Fields::Localized do

  context "when no default is provided" do

    let(:field) do
      described_class.new(:description, localize: true, type: String)
    end

    it "defaults to nil" do
      expect(field.default_val).to be_nil
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
        expect(field.default_val).to eq("No translation")
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
        expect(field.default_val).to eq(1)
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
          expect(value).to be_nil
        end
      end

      context "when no locale is defined" do

        let(:value) do
          field.demongoize({ "en" => "This is a test" })
        end

        it "returns the string from the default locale" do
          expect(value).to eq("This is a test")
        end
      end

      context "when a locale is provided" do
        with_default_i18n_configs

        before do
          ::I18n.locale = :de
        end

        context "when the value exists" do

          let(:value) do
            field.demongoize({ "de" => "This is a test" })
          end

          it "returns the string from the set locale" do
            expect(value).to eq("This is a test")
          end
        end

        context "when key is a symbol" do

          let(:value) do
            field.demongoize({ :de => "This is a test" })
          end

          it "returns the string from the set locale" do
            expect(value).to eq("This is a test")
          end
        end


        context "passing a bogus value" do

          let(:value) do
            field.demongoize("bogus")
          end

          it "returns nil" do
            expect(value).to be_nil
          end
        end

        context "when the value does not exist" do

          context "when not using fallbacks" do
            require_no_fallbacks

            let(:value) do
              field.demongoize({ "en" => "testing" })
            end

            it "returns nil" do
              expect(value).to be_nil
            end
          end

          context "when using fallbacks" do
            require_fallbacks

            context "when fallbacks are defined" do

              before do
                ::I18n.fallbacks[:de] = [ :de, :en, :es ]
              end

              context "when the first fallback translation exists" do

                let(:value) do
                  field.demongoize({ "en" => "testing" })
                end

                it "returns the fallback translation" do
                  expect(value).to eq("testing")
                end
              end

              context "when the fallback translation exists and is a symbol" do

                let(:value) do
                  field.demongoize({ :es => "testing" })
                end

                it "returns the fallback translation" do
                  expect(value).to eq("testing")
                end
              end

              context "when another fallback translation exists" do

                let(:value) do
                  field.demongoize({ "es" => "pruebas" })
                end

                it "returns the fallback translation" do
                  expect(value).to eq("pruebas")
                end
              end

              context "when the fallback translation does not exist" do

                let(:value) do
                  field.demongoize({ "fr" => "oui" })
                end

                it "returns nil" do
                  expect(value).to be_nil
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
                expect(value).to be_nil
              end
            end

            context 'when fallbacks are empty' do

              before do
                ::I18n.fallbacks[:de] = [ ]
              end

              let(:value) do
                field.demongoize({ 'de' => 'testen' })
              end

              it "returns the value" do
                expect(value).to eq('testen')
              end
            end
          end
        end
      end
    end

    context "when no type is provided" do

      let(:field) do
        described_class.new(:description, localize: true)
      end

      let(:value) do
        field.demongoize({ "en" => false })
      end

      it "allows booleans to be returned" do
        expect(value).to eq(false)
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
          expect(value).to be_nil
        end
      end

      context "when no locale is defined" do

        let(:value) do
          field.demongoize({ "en" => 100 })
        end

        it "returns the value from the default locale" do
          expect(value).to eq(100)
        end
      end

      context "when a locale is provided" do
        with_default_i18n_configs

        before do
          ::I18n.locale = :de
        end

        context "when the value exists" do

          let(:value) do
            field.demongoize({ "de" => 100 })
          end

          it "returns the value from the set locale" do
            expect(value).to eq(100)
          end
        end

        context "when the value does not exist" do

          context "when not using fallbacks" do

            let(:value) do
              field.demongoize({ "en" => 100 })
            end

            it "returns nil" do
              expect(value).to be_nil
            end
          end

          context "when using fallbacks" do
            require_fallbacks

            context "when fallbacks are defined" do
              with_default_i18n_configs

              before do
                ::I18n.fallbacks[:de] = [ :de, :en, :es ]
              end

              context 'when fallbacks are enabled' do

                context "when the first fallback translation exists" do

                  let(:value) do
                    field.demongoize({ "en" => 1 })
                  end

                  it "returns the fallback translation" do
                    expect(value).to eq(1)
                  end
                end

                context "when another fallback translation exists" do

                  let(:value) do
                    field.demongoize({ "es" => 100 })
                  end

                  it "returns the fallback translation" do
                    expect(value).to eq(100)
                  end
                end

                context "when the fallback translation does not exist" do

                  let(:value) do
                    field.demongoize({ "fr" => 50 })
                  end

                  it "returns nil" do
                    expect(value).to be_nil
                  end
                end
              end

              context 'when fallbacks are disabled' do

                let(:field) do
                  described_class.new(:description, localize: true, type: Integer, fallbacks: false)
                end

                let(:value) do
                  field.demongoize({ "es" => 100 })
                end

                it "returns nil" do
                  expect(value).to be_nil
                end
              end
            end

            context "when no fallbacks are defined" do
              with_default_i18n_configs

              before do
                ::I18n.fallbacks[:de] = [ :de ]
              end

              let(:value) do
                field.demongoize({ "es" => 100 })
              end

              it "returns nil" do
                expect(value).to be_nil
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
          expect(value).to eq({ "en" => "This is a test" })
        end
      end

      context "when a locale is provided" do
        with_default_i18n_configs

        before do
          ::I18n.locale = :de
        end

        let(:value) do
          field.mongoize("This is a test")
        end

        it "returns the string in the set locale" do
          expect(value).to eq({ "de" => "This is a test" })
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
          expect(value).to eq({ "en" => 100 })
        end
      end

      context "when a locale is provided" do
        with_default_i18n_configs

        before do
          ::I18n.locale = :de
        end

        let(:value) do
          field.mongoize("100")
        end

        it "returns the string in the set locale" do
          expect(value).to eq({ "de" => 100 })
        end
      end

      context 'when the type is Boolean' do
        with_default_i18n_configs

        before do
          ::I18n.locale = :de
        end

        context "when the value is false" do

          let(:field) do
            described_class.new(:boolean_value, localize: true, type: Mongoid::Boolean)
          end

          let(:value) do
            field.demongoize({ "de" => false })
          end

          it "returns the boolean value from the set locale" do
            expect(value).to eq(false)
          end
        end

        context "when the value is true" do

          let(:field) do
            described_class.new(:boolean_value, localize: true, type: Mongoid::Boolean)
          end

          let(:value) do
            field.demongoize({"de" => true})
          end

          it "returns the boolean value from the set locale" do
            expect(value).to eq(true)
          end
        end

        context "when fallbacks are defined" do
          require_fallbacks

          context "when the lookup does not need to use fallbacks" do

            context "when the value is false" do
              with_default_i18n_configs

              before do
                ::I18n.fallbacks[:de] = [:en, :es]
              end

              let(:field) do
                described_class.new(:boolean_value, localize: true, type: Mongoid::Boolean)
              end

              let(:value) do
                field.demongoize({"de" => false})
              end

              it "returns the boolean value from the set locale" do
                expect(value).to eq(false)
              end
            end

            context "when the value is true" do
              with_default_i18n_configs

              before do
                ::I18n.fallbacks[:de] = [:en, :es]
              end

              let(:field) do
                described_class.new(:boolean_value, localize: true, type: Mongoid::Boolean)
              end

              let(:value) do
                field.demongoize({"de" => true})
              end

              it "returns the boolean value from the set locale" do
                expect(value).to eq(true)
              end
            end
          end
        end
      end
    end
  end

  describe "localize: :present" do

    let(:field) do
      described_class.new(:description, localize: :present, type: String)
    end

    context "when setting the localize to present" do

      it "is localized?" do
        expect(field.localized?).to be true
      end

      it "is localize_present?" do
        expect(field.localize_present?).to be true
      end
    end

    context "when localize is not localize_present" do

      let(:field) do
        described_class.new(:description, localize: true, type: String)
      end

      it "is localized?" do
        expect(field.localized?).to be true
      end

      it "is not localize_present?" do
        expect(field.localize_present?).to be false
      end
    end
  end
end
