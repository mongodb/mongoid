require "spec_helper"

describe Mongoid::Validatable::UniquenessValidator do

  describe "#valid?" do

    context "when the document is a root document" do

      context "when adding custom persistence options" do

        before do
          Dictionary.validates_uniqueness_of :name
        end

        after do
          Dictionary.reset_callbacks(:validate)
        end

        context "when persisting to another collection" do

          before do
            Dictionary.with(collection: "dicts").create(name: "websters")
          end

          context "when the document is not valid" do

            let(:websters) do
              Dictionary.with(collection: "dicts").new(name: "websters")
            end

            it "performs the validation on the correct collection" do
              expect(websters).to_not be_valid
            end

            it "adds the uniqueness error" do
              websters.valid?
              expect(websters.errors[:name]).to_not be_nil
            end

            it "clears the persistence options in the thread local" do
              websters.valid?
              expect(Dictionary.persistence_options).to be_nil
            end
          end

          context "when the document is valid" do

            let(:oxford) do
              Dictionary.with(collection: "dicts").new(name: "oxford")
            end

            it "performs the validation on the correct collection" do
              expect(oxford).to be_valid
            end
          end
        end
      end

      context "when the document contains no compound key" do

        context "when validating a relation" do

          before do
            Word.validates_uniqueness_of :dictionary
          end

          after do
            Word.reset_callbacks(:validate)
          end

          context "when the attribute id is unique" do

            let(:dictionary) do
              Dictionary.create
            end

            let(:word) do
              Word.new(dictionary: dictionary)
            end

            it "returns true" do
              expect(word).to be_valid
            end
          end
        end

        context "when the field name is aliased" do

          before do
            Dictionary.create!(language: "en")
          end

          let(:dictionary) do
            Dictionary.new(language: "en")
          end

          after do
            Dictionary.reset_callbacks(:validate)
          end

          context "when the validation uses the aliased name" do

            before do
              Dictionary.validates_uniqueness_of :language
            end

            it "correctly detects a uniqueness conflict" do
              expect(dictionary).to_not be_valid
            end

            it "adds the uniqueness error to the aliased field name" do
              dictionary.valid?
              expect(dictionary.errors).to have_key(:language)
              expect(dictionary.errors[:language]).to eq([ "is already taken" ])
            end
          end

          context "when the validation uses the underlying field name" do

            before do
              Dictionary.validates_uniqueness_of :l
            end

            it "correctly detects a uniqueness conflict" do
              expect(dictionary).to_not be_valid
            end

            it "adds the uniqueness error to the underlying field name" do
              dictionary.valid?
              expect(dictionary.errors).to have_key(:l)
              expect(dictionary.errors[:l]).to eq([ "is already taken" ])
            end
          end
        end

        context "when the field is localized" do

          context "when no scope is provided" do

            context "when case sensitive is true" do

              before do
                Dictionary.validates_uniqueness_of :description
              end

              after do
                Dictionary.reset_callbacks(:validate)
              end

              context "when no attribute is set" do

                context "when no document with no value exists in the database" do

                  let(:dictionary) do
                    Dictionary.new
                  end

                  it "returns true" do
                    expect(dictionary).to be_valid
                  end
                end

                context "when a document with no value exists in the database" do

                  before do
                    Dictionary.create
                  end

                  let(:dictionary) do
                    Dictionary.new
                  end

                  it "returns false" do
                    expect(dictionary).to_not be_valid
                  end
                end
              end

              context "when the attribute is unique" do

                context "when single localization" do

                  before do
                    Dictionary.create(description: "english")
                  end

                  let(:dictionary) do
                    Dictionary.new(description: "English")
                  end

                  it "returns true" do
                    expect(dictionary).to be_valid
                  end
                end

                context "when multiple localizations" do

                  before do
                    Dictionary.
                        create(description_translations: { "en" => "english", "de" => "german" })
                  end

                  let(:dictionary) do
                    Dictionary.new(description_translations: { "en" => "English", "de" => "German" })
                  end

                  it "returns true" do
                    expect(dictionary).to be_valid
                  end
                end
              end

              context "when the attribute is not unique" do

                context "when the document is not the match" do

                  context "when single localization" do

                    before do
                      Dictionary.create(description: "english")
                    end

                    let(:dictionary) do
                      Dictionary.new(description: "english")
                    end

                    it "returns false" do
                      expect(dictionary).to_not be_valid
                    end

                    it "adds the uniqueness error" do
                      dictionary.valid?
                      expect(dictionary.errors[:description]).to eq([ "is already taken" ])
                    end
                  end

                  context "when multiple localizations" do

                    before do
                      Dictionary.
                          create(description_translations: { "en" => "english", "de" => "german" })
                    end

                    let(:dictionary) do
                      Dictionary.new(description_translations: { "en" => "english", "de" => "German" })
                    end

                    it "returns false" do
                      expect(dictionary).to_not be_valid
                    end

                    it "adds the uniqueness error" do
                      dictionary.valid?
                      expect(dictionary.errors[:description]).to eq([ "is already taken" ])
                    end
                  end
                end
              end
            end

            context "when case sensitive is false" do

              before do
                Dictionary.validates_uniqueness_of :description, case_sensitive: false
              end

              after do
                Dictionary.reset_callbacks(:validate)
              end

              context "when the attribute is unique" do

                context "when there are no special characters" do

                  before do
                    Dictionary.create(description: "english")
                  end

                  let(:dictionary) do
                    Dictionary.new(description: "german")
                  end

                  it "returns true" do
                    expect(dictionary).to be_valid
                  end
                end

                context "when special characters exist" do

                  before do
                    Dictionary.create(description: "english")
                  end

                  let(:dictionary) do
                    Dictionary.new(description: "en@gl.ish")
                  end

                  it "returns true" do
                    expect(dictionary).to be_valid
                  end
                end
              end

              context "when the attribute is not unique" do

                context "when the document is not the match" do

                  context "when signle localization" do

                    before do
                      Dictionary.create(description: "english")
                    end

                    let(:dictionary) do
                      Dictionary.new(description: "English")
                    end

                    it "returns false" do
                      expect(dictionary).to_not be_valid
                    end

                    it "adds the uniqueness error" do
                      dictionary.valid?
                      expect(dictionary.errors[:description]).to eq([ "is already taken" ])
                    end
                  end

                  context "when multiple localizations" do

                    before do
                      Dictionary.
                          create(description_translations: { "en" => "english", "de" => "german" })
                    end

                    let(:dictionary) do
                      Dictionary.new(description_translations: { "en" => "English", "de" => "German" })
                    end

                    it "returns false" do
                      expect(dictionary).to_not be_valid
                    end

                    it "adds the uniqueness error" do
                      dictionary.valid?
                      expect(dictionary.errors[:description]).to eq([ "is already taken" ])
                    end
                  end
                end

                context "when the document is the match in the database" do

                  let!(:dictionary) do
                    Dictionary.create(description: "english")
                  end

                  it "returns true" do
                    expect(dictionary).to be_valid
                  end
                end
              end
            end
          end

          context "when a scope is provided" do

            before do
              Dictionary.validates_uniqueness_of :description, scope: :name
            end

            after do
              Dictionary.reset_callbacks(:validate)
            end

            context "when the attribute is not unique in the scope" do

              context "when the document is not the match" do

                before do
                  Dictionary.
                    create(description: "english", name: "test")
                end

                let(:dictionary) do
                  Dictionary.new(description: "english", name: "test")
                end

                it "returns false" do
                  expect(dictionary).to_not be_valid
                end

                it "adds the uniqueness error" do
                  dictionary.valid?
                  expect(dictionary.errors[:description]).to eq([ "is already taken" ])
                end
              end
            end
          end
        end

        context "when no scope is provided" do

          before do
            Dictionary.validates_uniqueness_of :name
          end

          after do
            Dictionary.reset_callbacks(:validate)
          end

          context "when the attribute is unique" do

            let!(:oxford) do
              Dictionary.create(name: "Oxford")
            end

            let(:dictionary) do
              Dictionary.new(name: "Webster")
            end

            it "returns true" do
              expect(dictionary).to be_valid
            end

            context "when subsequently cloning the document" do

              let(:clone) do
                oxford.clone
              end

              it "returns false for the clone" do
                expect(clone).to_not be_valid
              end
            end
          end

          context "when the attribute is not unique" do

            context "when the document is not the match" do

              before do
                Dictionary.create(name: "Oxford")
              end

              let!(:dictionary) do
                Dictionary.new(name: "Oxford")
              end

              it "returns false" do
                expect(dictionary).to_not be_valid
              end

              it "adds the uniqueness error" do
                dictionary.valid?
                expect(dictionary.errors[:name]).to eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              context "when the field has changed" do

                let!(:dictionary) do
                  Dictionary.create(name: "Oxford")
                end

                it "returns true" do
                  expect(dictionary).to be_valid
                end
              end

              context "when the field has not changed" do

                before do
                  Dictionary.default_scoping = nil
                end

                let!(:dictionary) do
                  Dictionary.create!(name: "Oxford")
                end

                let!(:from_db) do
                  Dictionary.find(dictionary.id)
                end

                it "returns true" do
                  expect(from_db).to be_valid
                end

                it "does not touch the database" do
                  expect(Dictionary).to receive(:where).never
                  from_db.valid?
                end
              end
            end
          end
        end

        context "when a default scope is on the model" do

          before do
            Dictionary.validates_uniqueness_of :name
            Dictionary.default_scope(->{ Dictionary.where(year: 1990) })
          end

          after do
            Dictionary.default_scoping = nil
            Dictionary.reset_callbacks(:validate)
          end

          context "when the document with the unqiue attribute is not in default scope" do

            context "when the attribute is not unique" do

              before do
                Dictionary.create(name: "Oxford")
              end

              let(:dictionary) do
                Dictionary.new(name: "Oxford")
              end

              it "returns false" do
                expect(dictionary).to_not be_valid
              end
            end
          end
        end

        context "when an aliased scope is provided" do

          before do
            Dictionary.validates_uniqueness_of :name, scope: :language
          end

          after do
            Dictionary.reset_callbacks(:validate)
          end

          context "when the attribute is unique" do

            before do
              Dictionary.create(name: "Oxford", language: "English")
            end

            let(:dictionary) do
              Dictionary.new(name: "Webster")
            end

            it "returns true" do
              expect(dictionary).to be_valid
            end
          end

          context "when the attribute is unique in the scope" do

            before do
              Dictionary.create(name: "Oxford", language: "English")
            end

            let(:dictionary) do
              Dictionary.new(name: "Webster", language: "English")
            end

            it "returns true" do
              expect(dictionary).to be_valid
            end
          end

          context "when the attribute is not unique with no scope" do

            before do
              Dictionary.create(name: "Oxford", language: "English")
            end

            let(:dictionary) do
              Dictionary.new(name: "Oxford")
            end

            it "returns true" do
              expect(dictionary).to be_valid
            end
          end

          context "when the attribute is not unique in another scope" do

            before do
              Dictionary.create(name: "Oxford", language: "English")
            end

            let(:dictionary) do
              Dictionary.new(name: "Oxford", language: "Deutsch")
            end

            it "returns true" do
              expect(dictionary).to be_valid
            end
          end

          context "when the attribute is not unique in the same scope" do

            context "when the document is not the match" do

              before do
                Dictionary.create(name: "Oxford", language: "English")
              end

              let(:dictionary) do
                Dictionary.new(name: "Oxford", language: "English")
              end

              it "returns false" do
                expect(dictionary).to_not be_valid
              end

              it "adds the uniqueness errors" do
                dictionary.valid?
                expect(dictionary.errors[:name]).to eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:dictionary) do
                Dictionary.create(name: "Oxford", language: "English")
              end

              it "returns true" do
                expect(dictionary).to be_valid
              end
            end
          end
        end

        context "when a single scope is provided" do

          before do
            Dictionary.validates_uniqueness_of :name, scope: :publisher
          end

          after do
            Dictionary.reset_callbacks(:validate)
          end

          context "when the attribute is unique" do

            before do
              Dictionary.create(name: "Oxford", publisher: "Amazon")
            end

            let(:dictionary) do
              Dictionary.new(name: "Webster")
            end

            it "returns true" do
              expect(dictionary).to be_valid
            end
          end

          context "when the attribute is unique in the scope" do

            before do
              Dictionary.create(name: "Oxford", publisher: "Amazon")
            end

            let(:dictionary) do
              Dictionary.new(name: "Webster", publisher: "Amazon")
            end

            it "returns true" do
              expect(dictionary).to be_valid
            end
          end

          context "when uniqueness is violated due to scope change" do

            let(:personal_folder) do
              Folder.create!(name: "Personal")
            end

            let(:public_folder) do
              Folder.create!(name: "Public")
            end

            before do
              personal_folder.folder_items << FolderItem.new(name: "non-unique")
              public_folder.folder_items << FolderItem.new(name: "non-unique")
            end

            let(:item) do
              public_folder.folder_items.last
            end

            it "should set an error for associated object not being unique" do
              item.update_attributes(folder_id: personal_folder.id)
              expect(item.errors.messages[:name].first).to eq("is already taken")
            end
          end

          context "when the attribute is not unique with no scope" do

            before do
              Dictionary.create(name: "Oxford", publisher: "Amazon")
            end

            let(:dictionary) do
              Dictionary.new(name: "Oxford")
            end

            it "returns true" do
              expect(dictionary).to be_valid
            end
          end

          context "when the attribute is not unique in another scope" do

            before do
              Dictionary.create(name: "Oxford", publisher: "Amazon")
            end

            let(:dictionary) do
              Dictionary.new(name: "Oxford", publisher: "Addison")
            end

            it "returns true" do
              expect(dictionary).to be_valid
            end
          end

          context "when the attribute is not unique in the same scope" do

            context "when the document is not the match" do

              before do
                Dictionary.create(name: "Oxford", publisher: "Amazon")
              end

              let(:dictionary) do
                Dictionary.new(name: "Oxford", publisher: "Amazon")
              end

              it "returns false" do
                expect(dictionary).to_not be_valid
              end

              it "adds the uniqueness errors" do
                dictionary.valid?
                expect(dictionary.errors[:name]).to eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:dictionary) do
                Dictionary.create(name: "Oxford", publisher: "Amazon")
              end

              it "returns true" do
                expect(dictionary).to be_valid
              end
            end

            context "when one of the scopes is a time" do

              before do
                Dictionary.create(
                  name: "Oxford",
                  publisher: "Amazon",
                  published: 10.days.ago.to_time
                )
              end

              let(:dictionary) do
                Dictionary.new(
                  name: "Oxford",
                  publisher: "Amazon",
                  published: 10.days.ago.to_time
                )
              end

              it "returns false" do
                expect(dictionary).to_not be_valid
              end

              it "adds the uniqueness errors" do
                dictionary.valid?
                expect(dictionary.errors[:name]).to eq([ "is already taken" ])
              end
            end
          end
        end

        context "when a range scope is provided" do

          before do
            Dictionary.validates_uniqueness_of(:name, :scope => Dictionary.where(:year.gte => 1900, :year.lt => 2000))
            Dictionary.create(name: "French-English", year: 1950)
            Dictionary.create(name: "French-English", year: 1960)
          end

          after do
            Dictionary.reset_callbacks(:validate)
          end

          it "successfully prevents uniqueness violation" do
            expect(Dictionary.all.size).to eq(1)
          end
        end

        context "when multiple scopes are provided" do

          before do
            Dictionary.validates_uniqueness_of :name, scope: [ :publisher, :year ]
          end

          after do
            Dictionary.reset_callbacks(:validate)
          end

          context "when the attribute is unique" do

            before do
              Dictionary.create(name: "Oxford", publisher: "Amazon")
            end

            let(:dictionary) do
              Dictionary.new(name: "Webster")
            end

            it "returns true" do
              expect(dictionary).to be_valid
            end
          end

          context "when the attribute is unique in the scope" do

            before do
              Dictionary.create(
                name: "Oxford",
                publisher: "Amazon",
                year: 2011
              )
            end

            let(:dictionary) do
              Dictionary.new(
                name: "Webster",
                publisher: "Amazon",
                year: 2011
              )
            end

            it "returns true" do
              expect(dictionary).to be_valid
            end
          end

          context "when the attribute is not unique with no scope" do

            before do
              Dictionary.create(name: "Oxford", publisher: "Amazon")
            end

            let(:dictionary) do
              Dictionary.new(name: "Oxford")
            end

            it "returns true" do
              expect(dictionary).to be_valid
            end
          end

          context "when the attribute is not unique in another scope" do

            before do
              Dictionary.create(
                name: "Oxford",
                publisher: "Amazon",
                year: 1995
              )
            end

            let(:dictionary) do
              Dictionary.new(
                name: "Oxford",
                publisher: "Addison",
                year: 2011
              )
            end

            it "returns true" do
              expect(dictionary).to be_valid
            end
          end

          context "when the attribute is not unique in the same scope" do

            context "when the document is not the match" do

              before do
                Dictionary.create(
                  name: "Oxford",
                  publisher: "Amazon",
                  year: 1960
                )
              end

              let(:dictionary) do
                Dictionary.new(
                  name: "Oxford",
                  publisher: "Amazon",
                  year: 1960
                )
              end

              it "returns false" do
                expect(dictionary).to_not be_valid
              end

              it "adds the uniqueness errors" do
                dictionary.valid?
                expect(dictionary.errors[:name]).to eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:dictionary) do
                Dictionary.create(
                  name: "Oxford",
                  publisher: "Amazon",
                  year: 1960
                )
              end

              it "returns true" do
                expect(dictionary).to be_valid
              end
            end
          end
        end

        context "when case sensitive is true" do

          before do
            Dictionary.validates_uniqueness_of :name
          end

          after do
            Dictionary.reset_callbacks(:validate)
          end

          context "when the attribute is unique" do

            before do
              Dictionary.create(name: "Oxford")
            end

            let(:dictionary) do
              Dictionary.new(name: "Webster")
            end

            it "returns true" do
              expect(dictionary).to be_valid
            end
          end

          context "when the attribute is not unique" do

            context "when the document is not the match" do

              before do
                Dictionary.create(name: "Oxford")
              end

              let(:dictionary) do
                Dictionary.new(name: "Oxford")
              end

              it "returns false" do
                expect(dictionary).to_not be_valid
              end

              it "adds the uniqueness error" do
                dictionary.valid?
                expect(dictionary.errors[:name]).to eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:dictionary) do
                Dictionary.create(name: "Oxford")
              end

              it "returns true" do
                expect(dictionary).to be_valid
              end
            end
          end
        end

        context "when case sensitive is false" do

          before do
            Dictionary.validates_uniqueness_of :name, case_sensitive: false
          end

          after do
            Dictionary.reset_callbacks(:validate)
          end

          context "when the attribute is unique" do

            context "when there are no special characters" do

              before do
                Dictionary.create(name: "Oxford")
              end

              let(:dictionary) do
                Dictionary.new(name: "Webster")
              end

              it "returns true" do
                expect(dictionary).to be_valid
              end
            end

            context "when special characters exist" do

              before do
                Dictionary.create(name: "Oxford")
              end

              let(:dictionary) do
                Dictionary.new(name: "Web@st.er")
              end

              it "returns true" do
                expect(dictionary).to be_valid
              end
            end
          end

          context "when the attribute is not unique" do

            context "when the document is not the match" do

              before do
                Dictionary.create(name: "Oxford")
              end

              let(:dictionary) do
                Dictionary.new(name: "oxford")
              end

              it "returns false" do
                expect(dictionary).to_not be_valid
              end

              it "adds the uniqueness error" do
                dictionary.valid?
                expect(dictionary.errors[:name]).to eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:dictionary) do
                Dictionary.create(name: "Oxford")
              end

              it "returns true" do
                expect(dictionary).to be_valid
              end
            end
          end
        end

        context "when not allowing nil" do

          it "raises a validation error" do
            expect { LineItem.create! }.to raise_error Mongoid::Errors::Validations
          end
        end

        context "when allowing nil" do

          before do
            Dictionary.validates_uniqueness_of :name, allow_nil: true
          end

          after do
            Dictionary.reset_callbacks(:validate)
          end

          context "when the attribute is nil" do

            before do
              Dictionary.create
            end

            let(:dictionary) do
              Dictionary.new
            end

            it "returns true" do
              expect(dictionary).to be_valid
            end
          end
        end

        context "when allowing blank" do

          before do
            Dictionary.validates_uniqueness_of :name, allow_blank: true
          end

          after do
            Dictionary.reset_callbacks(:validate)
          end

          context "when the attribute is blank" do

            before do
              Dictionary.create(name: "")
            end

            let(:dictionary) do
              Dictionary.new(name: "")
            end

            it "returns true" do
              expect(dictionary).to be_valid
            end
          end
        end
      end

      context "when the document contains a compound key" do

        context "when no scope is provided" do

          before do
            Login.validates_uniqueness_of :username
          end

          after do
            Login.reset_callbacks(:validate)
          end

          context "when the attribute is unique" do

            before do
              Login.create(username: "Oxford")
            end

            let(:login) do
              Login.new(username: "Webster")
            end

            it "returns true" do
              expect(login).to be_valid
            end
          end

          context "when the attribute is not unique" do

            context "when the document is not the match" do

              before do
                Login.create(username: "Oxford")
              end

              let(:login) do
                Login.new(username: "Oxford")
              end

              it "returns false" do
                expect(login).to_not be_valid
              end

              it "adds the uniqueness error" do
                login.valid?
                expect(login.errors[:username]).to eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:login) do
                Login.create(username: "Oxford")
              end

              it "returns true" do
                expect(login).to be_valid
              end
            end
          end
        end

        context "when a single scope is provided" do

          before do
            Login.validates_uniqueness_of :username, scope: :application_id
          end

          after do
            Login.reset_callbacks(:validate)
          end

          context "when the attribute is unique" do

            before do
              Login.create(username: "Oxford", application_id: 1)
            end

            let(:login) do
              Login.new(username: "Webster")
            end

            it "returns true" do
              expect(login).to be_valid
            end
          end

          context "when the attribute is unique in the scope" do

            before do
              Login.create(username: "Oxford", application_id: 1)
            end

            let(:login) do
              Login.new(username: "Webster", application_id: 1)
            end

            it "returns true" do
              expect(login).to be_valid
            end
          end

          context "when the attribute is not unique with no scope" do

            before do
              Login.create(username: "Oxford", application_id: 1)
            end

            let(:login) do
              Login.new(username: "Oxford")
            end

            it "returns true" do
              expect(login).to be_valid
            end
          end

          context "when the attribute is not unique in another scope" do

            before do
              Login.create(username: "Oxford", application_id: 1)
            end

            let(:login) do
              Login.new(username: "Oxford", application_id: 2)
            end

            it "returns true" do
              expect(login).to be_valid
            end
          end

          context "when the attribute is not unique in the same scope" do

            context "when the document is not the match" do

              before do
                Login.create(username: "Oxford", application_id: 1)
              end

              let(:login) do
                Login.new(username: "Oxford", application_id: 1)
              end

              it "returns false" do
                expect(login).to_not be_valid
              end

              it "adds the uniqueness errors" do
                login.valid?
                expect(login.errors[:username]).to eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:login) do
                Login.create(username: "Oxford", application_id: 1)
              end

              it "returns true" do
                expect(login).to be_valid
              end
            end
          end
        end

        context "when case sensitive is true" do

          before do
            Login.validates_uniqueness_of :username
          end

          after do
            Login.reset_callbacks(:validate)
          end

          context "when the attribute is unique" do

            before do
              Login.create(username: "Oxford")
            end

            let(:login) do
              Login.new(username: "Webster")
            end

            it "returns true" do
              expect(login).to be_valid
            end
          end

          context "when the attribute is not unique" do

            context "when the document is not the match" do

              before do
                Login.create(username: "Oxford")
              end

              let(:login) do
                Login.new(username: "Oxford")
              end

              it "returns false" do
                expect(login).to_not be_valid
              end

              it "adds the uniqueness error" do
                login.valid?
                expect(login.errors[:username]).to eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:login) do
                Login.create(username: "Oxford")
              end

              it "returns true" do
                expect(login).to be_valid
              end
            end
          end
        end

        context "when case sensitive is false" do

          before do
            Login.validates_uniqueness_of :username, case_sensitive: false
          end

          after do
            Login.reset_callbacks(:validate)
          end

          context "when the attribute is unique" do

            context "when there are no special characters" do

              before do
                Login.create(username: "Oxford")
              end

              let(:login) do
                Login.new(username: "Webster")
              end

              it "returns true" do
                expect(login).to be_valid
              end
            end

            context "when special characters exist" do

              before do
                Login.create(username: "Oxford")
              end

              let(:login) do
                Login.new(username: "Web@st.er")
              end

              it "returns true" do
                expect(login).to be_valid
              end
            end
          end

          context "when the attribute is not unique" do

            context "when the document is not the match" do

              before do
                Login.create(username: "Oxford")
              end

              let(:login) do
                Login.new(username: "oxford")
              end

              it "returns false" do
                expect(login).to_not be_valid
              end

              it "adds the uniqueness error" do
                login.valid?
                expect(login.errors[:username]).to eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:login) do
                Login.create(username: "Oxford")
              end

              it "returns true" do
                expect(login).to be_valid
              end
            end
          end
        end

        context "when allowing nil" do

          before do
            Login.validates_uniqueness_of :username, allow_nil: true
          end

          after do
            Login.reset_callbacks(:validate)
          end

          context "when the attribute is nil" do

            before do
              Login.create
            end

            let(:login) do
              Login.new
            end

            it "returns true" do
              expect(login).to be_valid
            end
          end
        end

        context "when allowing blank" do

          before do
            Login.validates_uniqueness_of :username, allow_blank: true
          end

          after do
            Login.reset_callbacks(:validate)
          end

          context "when the attribute is blank" do

            before do
              Login.create(username: "")
            end

            let(:login) do
              Login.new(username: "")
            end

            it "returns true" do
              expect(login).to be_valid
            end
          end
        end
      end

      context "when the attribute is a custom type" do

        before do
          Bar.validates_uniqueness_of :lat_lng
        end

        after do
          Bar.reset_callbacks(:validate)
        end

        context "when the attribute is unique" do

          before do
            Bar.create(lat_lng: LatLng.new(52.30, 13.25))
          end

          let(:unique_bar) do
            Bar.new(lat_lng: LatLng.new(54.30, 14.25))
          end

          it "returns true" do
            expect(unique_bar).to be_valid
          end

        end

        context "when the attribute is not unique" do

          before do
            Bar.create(lat_lng: LatLng.new(52.30, 13.25))
          end

          let(:non_unique_bar) do
            Bar.new(lat_lng: LatLng.new(52.30, 13.25))
          end

          it "returns false" do
            expect(non_unique_bar).to_not be_valid
          end

        end
      end

      context "when conditions is set" do

        before do
          Band.validates_uniqueness_of :name, conditions: ->{ Band.where(active: true) }
        end

        after do
          Band.reset_callbacks(:validate)
        end

        context "when the attribute is unique" do

          before do
            Band.create(name: 'Foo', active: false)
          end

          let(:unique_band) do
            Band.new(name: 'Foo')
          end

          it "returns true" do
            expect(unique_band).to be_valid
          end

        end

        context "when the attribute is not unique" do

          before do
            Band.create(name: 'Foo')
          end

          let(:non_unique_band) do
            Band.new(name: 'Foo')
          end

          it "returns false" do
            expect(non_unique_band).to_not be_valid
          end
        end
      end
    end
  end

  context "when the document is embedded" do

    let(:word) do
      Word.create(name: "Schadenfreude")
    end

    context "when in an embeds_many" do

      let!(:def_one) do
        word.definitions.create(description: "1")
      end

      let!(:def_two) do
        word.definitions.create(description: "2")
      end

      context "when a document is being destroyed" do

        before do
          Definition.validates_uniqueness_of :description
        end

        after do
          Definition.reset_callbacks(:validate)
        end

        context "when changing a document to the destroyed property" do

          let(:attributes) do
            {
              definitions_attributes: {
                "0" => { id: def_one.id, description: "0", "_destroy" => 1 },
                "1" => { id: def_two.id, description: "1" }
              }
            }
          end

          before do
            word.attributes = attributes
          end

          it "returns true" do
            expect(def_two).to be_valid
          end
        end
      end

      context "when the document does not use composite keys" do

        context "when no scope is provided" do

          before do
            Definition.validates_uniqueness_of :description
          end

          after do
            Definition.reset_callbacks(:validate)
          end

          context "when the attribute is unique" do

            before do
              word.definitions.build(description: "Malicious joy")
            end

            let(:definition) do
              word.definitions.build(description: "Gloating")
            end

            it "returns true" do
              expect(definition).to be_valid
            end
          end

          context "when the attribute is not unique" do

            context "when the document is not the match" do

              before do
                word.definitions.build(description: "Malicious joy")
              end

              let(:definition) do
                word.definitions.build(description: "Malicious joy")
              end

              it "returns false" do
                expect(definition).to_not be_valid
              end

              it "adds the uniqueness error" do
                definition.valid?
                expect(definition.errors[:description]).to eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:definition) do
                word.definitions.build(description: "Malicious joy")
              end

              it "returns true" do
                expect(definition).to be_valid
              end
            end
          end
        end

        context "when a single scope is provided" do

          before do
            Definition.validates_uniqueness_of :description, scope: :part
          end

          after do
            Definition.reset_callbacks(:validate)
          end

          context "when the attribute is unique" do

            before do
              word.definitions.build(
                description: "Malicious joy", part: "Noun"
              )
            end

            let(:definition) do
              word.definitions.build(description: "Gloating")
            end

            it "returns true" do
              expect(definition).to be_valid
            end
          end

          context "when the attribute is unique in the scope" do

            before do
              word.definitions.build(
                description: "Malicious joy",
                part: "Noun"
              )
            end

            let(:definition) do
              word.definitions.build(
                description: "Gloating",
                part: "Noun"
              )
            end

            it "returns true" do
              expect(definition).to be_valid
            end
          end

          context "when the attribute is not unique with no scope" do

            before do
              word.definitions.build(
                description: "Malicious joy",
                part: "Noun"
              )
            end

            let(:definition) do
              word.definitions.build(description: "Malicious joy")
            end

            it "returns true" do
              expect(definition).to be_valid
            end
          end

          context "when the attribute is not unique in another scope" do

            before do
              word.definitions.build(
                description: "Malicious joy",
                part: "Noun"
              )
            end

            let(:definition) do
              word.definitions.build(
                description: "Malicious joy",
                part: "Adj"
              )
            end

            it "returns true" do
              expect(definition).to be_valid
            end
          end

          context "when the attribute is not unique in the same scope" do

            context "when the document is not the match" do

              before do
                word.definitions.build(
                  description: "Malicious joy",
                  part: "Noun"
                )
              end

              let(:definition) do
                word.definitions.build(
                  description: "Malicious joy",
                  part: "Noun"
                )
              end

              it "returns false" do
                expect(definition).to_not be_valid
              end

              it "adds the uniqueness errors" do
                definition.valid?
                expect(definition.errors[:description]).to eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:definition) do
                word.definitions.build(
                  description: "Malicious joy",
                  part: "Noun"
                )
              end

              it "returns true" do
                expect(definition).to be_valid
              end
            end
          end
        end

        context "when multiple scopes are provided" do

          before do
            Definition.validates_uniqueness_of :description, scope: [ :part, :regular ]
          end

          after do
            Definition.reset_callbacks(:validate)
          end

          context "when the attribute is unique" do

            before do
              word.definitions.build(
                description: "Malicious joy",
                part: "Noun"
              )
            end

            let(:definition) do
              word.definitions.build(description: "Gloating")
            end

            it "returns true" do
              expect(definition).to be_valid
            end
          end

          context "when the attribute is unique in the scope" do

            before do
              word.definitions.build(
                description: "Malicious joy",
                part: "Noun",
                regular: true
              )
            end

            let(:definition) do
              word.definitions.build(
                description: "Gloating",
                part: "Noun",
                regular: true
              )
            end

            it "returns true" do
              expect(definition).to be_valid
            end
          end

          context "when the attribute is not unique with no scope" do

            before do
              word.definitions.build(
                description: "Malicious joy",
                part: "Noun"
              )
            end

            let(:definition) do
              word.definitions.build(description: "Malicious scope")
            end

            it "returns true" do
              expect(definition).to be_valid
            end
          end

          context "when the attribute is not unique in another scope" do

            before do
              word.definitions.build(
                description: "Malicious joy",
                part: "Noun",
                regular: true
              )
            end

            let(:definition) do
              word.definitions.build(
                description: "Malicious joy",
                part: "Adj",
                regular: true
              )
            end

            it "returns true" do
              expect(definition).to be_valid
            end
          end

          context "when the attribute is not unique in the same scope" do

            context "when the document is not the match" do

              before do
                word.definitions.build(
                  description: "Malicious joy",
                  part: "Noun",
                  regular: true
                )
              end

              let(:definition) do
                word.definitions.build(
                  description: "Malicious joy",
                  part: "Noun",
                  regular: true
                )
              end

              it "returns false" do
                expect(definition).to_not be_valid
              end

              it "adds the uniqueness errors" do
                definition.valid?
                expect(definition.errors[:description]).to eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:definition) do
                word.definitions.build(
                  description: "Malicious joy",
                  part: "Noun",
                  regular: false
                )
              end

              it "returns true" do
                expect(definition).to be_valid
              end
            end
          end
        end

        context "when case sensitive is true" do

          before do
            Definition.validates_uniqueness_of :description
          end

          after do
            Definition.reset_callbacks(:validate)
          end

          context "when the attribute is unique" do

            before do
              word.definitions.build(description: "Malicious jo")
            end

            let(:definition) do
              word.definitions.build(description: "Gloating")
            end

            it "returns true" do
              expect(definition).to be_valid
            end
          end

          context "when the attribute is not unique" do

            context "when the document is not the match" do

              before do
                word.definitions.build(description: "Malicious joy")
              end

              let(:definition) do
                word.definitions.build(description: "Malicious joy")
              end

              it "returns false" do
                expect(definition).to_not be_valid
              end

              it "adds the uniqueness error" do
                definition.valid?
                expect(definition.errors[:description]).to eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:definition) do
                word.definitions.build(description: "Malicious joy")
              end

              it "returns true" do
                expect(definition).to be_valid
              end
            end
          end
        end

        context "when case sensitive is false" do

          before do
            Definition.validates_uniqueness_of :description, case_sensitive: false
          end

          after do
            Definition.reset_callbacks(:validate)
          end

          context "when the attribute is unique" do

            context "when there are no special characters" do

              before do
                word.definitions.build(description: "Malicious joy")
              end

              let(:definition) do
                word.definitions.build(description: "Gloating")
              end

              it "returns true" do
                expect(definition).to be_valid
              end
            end

            context "when special characters exist" do

              before do
                word.definitions.build(description: "Malicious joy")
              end

              let(:definition) do
                word.definitions.build(description: "M@licious.joy")
              end

              it "returns true" do
                expect(definition).to be_valid
              end
            end
          end

          context "when the attribute is not unique" do

            context "when the document is not the match" do

              before do
                word.definitions.build(description: "Malicious joy")
              end

              let(:definition) do
                word.definitions.build(description: "Malicious JOY")
              end

              it "returns false" do
                expect(definition).to_not be_valid
              end

              it "adds the uniqueness error" do
                definition.valid?
                expect(definition.errors[:description]).to eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:definition) do
                word.definitions.build(description: "Malicious joy")
              end

              it "returns true" do
                expect(definition).to be_valid
              end
            end
          end
        end

        context "when allowing nil" do

          before do
            Definition.validates_uniqueness_of :description, allow_nil: true
          end

          after do
            Definition.reset_callbacks(:validate)
          end

          context "when the attribute is nil" do

            before do
              word.definitions.build
            end

            let(:definition) do
              word.definitions.build
            end

            it "returns true" do
              expect(definition).to be_valid
            end
          end
        end

        context "when allowing blank" do

          before do
            Definition.validates_uniqueness_of :description, allow_blank: true
          end

          after do
            Definition.reset_callbacks(:validate)
          end

          context "when the attribute is blank" do

            before do
              word.definitions.build(description: "")
            end

            let(:definition) do
              word.definitions.build(description: "")
            end

            it "returns true" do
              expect(definition).to be_valid
            end
          end
        end

        context "when the field name is aliased" do

          before do
            word.definitions.build(part: "noun", synonyms: "foo")
          end

          let(:definition) do
            word.definitions.build(part: "noun", synonyms: "foo")
          end

          after do
            Definition.reset_callbacks(:validate)
          end

          context "when the validation uses the aliased name" do

            before do
              Definition.validates_uniqueness_of :part, case_sensitive: false
            end

            it "correctly detects a uniqueness conflict" do
              expect(definition).to_not be_valid
            end

            it "adds the uniqueness error to the aliased field name" do
              definition.valid?
              expect(definition.errors).to have_key(:part)
              expect(definition.errors[:part]).to eq([ "is already taken" ])
            end
          end

          context "when the validation uses the underlying field name" do

            before do
              Definition.validates_uniqueness_of :p, case_sensitive: false
            end

            it "correctly detects a uniqueness conflict" do
              expect(definition).to_not be_valid
            end

            it "adds the uniqueness error to the underlying field name" do
              definition.valid?
              expect(definition.errors).to have_key(:p)
              expect(definition.errors[:p]).to eq([ "is already taken" ])
            end
          end

          context "when the field is localized" do

            context "when the validation uses the aliased name" do

              before do
                Definition.validates_uniqueness_of :synonyms, case_sensitive: false
              end

              it "correctly detects a uniqueness conflict" do
                expect(definition).to_not be_valid
              end

              it "adds the uniqueness error to the aliased field name" do
                definition.valid?
                expect(definition.errors).to have_key(:synonyms)
                expect(definition.errors[:synonyms]).to eq([ "is already taken" ])
              end
            end

            context "when the validation uses the underlying field name" do

              before do
                Definition.validates_uniqueness_of :syn, case_sensitive: false
              end

              it "correctly detects a uniqueness conflict" do
                expect(definition).to_not be_valid
              end

              it "adds the uniqueness error to the aliased field name" do
                definition.valid?
                expect(definition.errors).to have_key(:syn)
                expect(definition.errors[:syn]).to eq([ "is already taken" ])
              end
            end
          end
        end
      end

      context "when the document uses composite keys" do

        context "when no scope is provided" do

          before do
            WordOrigin.validates_uniqueness_of :origin_id
          end

          after do
            WordOrigin.reset_callbacks(:validate)
          end

          context "when the attribute is unique" do

            before do
              word.word_origins.build(origin_id: 1)
            end

            let(:word_origin) do
              word.word_origins.build(origin_id: 2)
            end

            it "returns true" do
              expect(word_origin).to be_valid
            end
          end

          context "when the attribute is not unique" do

            context "when the document is not the match" do

              before do
                word.word_origins.build(origin_id: 1)
              end

              let(:word_origin) do
                word.word_origins.build(origin_id: 1)
              end

              it "returns false" do
                expect(word_origin).to_not be_valid
              end

              it "adds the uniqueness error" do
                word_origin.valid?
                expect(word_origin.errors[:origin_id]).to eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:word_origin) do
                word.word_origins.build(origin_id: 1)
              end

              it "returns true" do
                expect(word_origin).to be_valid
              end
            end
          end
        end

        context "when allowing nil" do

          before do
            WordOrigin.validates_uniqueness_of :origin_id, allow_nil: true
          end

          after do
            WordOrigin.reset_callbacks(:validate)
          end

          context "when the attribute is nil" do

            before do
              word.word_origins.build
            end

            let(:word_origin) do
              word.word_origins.build
            end

            it "returns true" do
              expect(word_origin).to be_valid
            end
          end
        end

        context "when allowing blank" do

          before do
            WordOrigin.validates_uniqueness_of :origin_id, allow_blank: true
          end

          after do
            WordOrigin.reset_callbacks(:validate)
          end

          context "when the attribute is blank" do

            before do
              word.word_origins.build(origin_id: "")
            end

            let(:word_origin) do
              word.word_origins.build(origin_id: "")
            end

            it "returns true" do
              expect(word_origin).to be_valid
            end
          end
        end
      end
    end

    context "when in an embeds_one" do

      before do
        Pronunciation.validates_uniqueness_of :sound
      end

      after do
        Pronunciation.reset_callbacks(:validate)
      end

      let(:pronunciation) do
        word.build_pronunciation(sound: "Schwa")
      end

      it "always returns true" do
        expect(pronunciation).to be_valid
      end
    end
  end

  context "when describing validation on the instance level" do

    let!(:dictionary) do
      Dictionary.create!(name: "en")
    end

    let(:validators) do
      dictionary.validates_uniqueness_of :name
    end

    it "adds the validation only to the instance" do
      expect(validators).to eq([ described_class ])
    end
  end

  context "when validation works with inheritance" do
    class EuropeanActor < Actor
      validates_uniqueness_of :name
    end

    class SpanishActor < EuropeanActor
    end

    before do
      EuropeanActor.create!(name: "Antonio Banderas")
    end

    let!(:subclass_document_with_duplicated_name) do
      SpanishActor.new(name: "Antonio Banderas")
    end

    it "should be invalid" do
      subclass_document_with_duplicated_name.tap do |d|
        expect(d).to be_invalid
        expect(d.errors[:name]).to eq([ "is already taken" ])
      end
    end
  end

  context "when persisting with safe options" do

    before do
      Person.validates_uniqueness_of(:username)
      Person.create_indexes
    end

    let!(:person) do
      Person.create(ssn: "132-11-1111", username: "aaasdaffff")
    end

    after do
      Person.reset_callbacks(:validate)
    end

    it "transfers the options to the cloned client" do
      expect {
        Person.create!(ssn: "132-11-1111", username: "asdfsdfA")
      }.to raise_error
    end
  end
end
