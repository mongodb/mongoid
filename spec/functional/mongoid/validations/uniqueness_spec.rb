require "spec_helper"

describe Mongoid::Validations::UniquenessValidator do

  before do
    [ Dictionary, Login, Word ].each(&:delete_all)
  end

  describe "#valid?" do

    context "when the document is a root document" do

      context "when the document contains no compound key" do

        context "when no scope is provided" do

          before do
            Dictionary.validates_uniqueness_of :name
          end

          after do
            Dictionary._validators.clear
            Dictionary._validate_callbacks.clear
          end

          context "when the attribute is unique" do

            before do
              Dictionary.create(:name => "Oxford")
            end

            let(:dictionary) do
              Dictionary.new(:name => "Webster")
            end

            it "returns true" do
              dictionary.should be_valid
            end
          end

          context "when the attribute is not unique" do

            context "when the document is not the match" do

              before do
                Dictionary.create(:name => "Oxford")
              end

              let(:dictionary) do
                Dictionary.new(:name => "Oxford")
              end

              it "returns false" do
                dictionary.should_not be_valid
              end

              it "adds the uniqueness error" do
                dictionary.valid?
                dictionary.errors[:name].should eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:dictionary) do
                Dictionary.create(:name => "Oxford")
              end

              it "returns true" do
                dictionary.should be_valid
              end
            end
          end
        end

        context "when a single scope is provided" do

          before do
            Dictionary.validates_uniqueness_of :name, :scope => :publisher
          end

          after do
            Dictionary._validators.clear
            Dictionary._validate_callbacks.clear
          end

          context "when the attribute is unique" do

            before do
              Dictionary.create(:name => "Oxford", :publisher => "Amazon")
            end

            let(:dictionary) do
              Dictionary.new(:name => "Webster")
            end

            it "returns true" do
              dictionary.should be_valid
            end
          end

          context "when the attribute is unique in the scope" do

            before do
              Dictionary.create(:name => "Oxford", :publisher => "Amazon")
            end

            let(:dictionary) do
              Dictionary.new(:name => "Webster", :publisher => "Amazon")
            end

            it "returns true" do
              dictionary.should be_valid
            end
          end

          context "when the attribute is not unique with no scope" do

            before do
              Dictionary.create(:name => "Oxford", :publisher => "Amazon")
            end

            let(:dictionary) do
              Dictionary.new(:name => "Oxford")
            end

            it "returns true" do
              dictionary.should be_valid
            end
          end

          context "when the attribute is not unique in another scope" do

            before do
              Dictionary.create(:name => "Oxford", :publisher => "Amazon")
            end

            let(:dictionary) do
              Dictionary.new(:name => "Oxford", :publisher => "Addison")
            end

            it "returns true" do
              dictionary.should be_valid
            end
          end

          context "when the attribute is not unique in the same scope" do

            context "when the document is not the match" do

              before do
                Dictionary.create(:name => "Oxford", :publisher => "Amazon")
              end

              let(:dictionary) do
                Dictionary.new(:name => "Oxford", :publisher => "Amazon")
              end

              it "returns false" do
                dictionary.should_not be_valid
              end

              it "adds the uniqueness errors" do
                dictionary.valid?
                dictionary.errors[:name].should eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:dictionary) do
                Dictionary.create(:name => "Oxford", :publisher => "Amazon")
              end

              it "returns true" do
                dictionary.should be_valid
              end
            end

            context "when one of the scopes is a time" do

              before do
                Dictionary.create(
                  :name => "Oxford",
                  :publisher => "Amazon",
                  :published => 10.days.ago.to_time
                )
              end

              let(:dictionary) do
                Dictionary.new(
                  :name => "Oxford",
                  :publisher => "Amazon",
                  :published => 10.days.ago.to_time
                )
              end

              it "returns false" do
                dictionary.should_not be_valid
              end

              it "adds the uniqueness errors" do
                dictionary.valid?
                dictionary.errors[:name].should eq([ "is already taken" ])
              end
            end
          end
        end

        context "when multiple scopes are provided" do

          before do
            Dictionary.validates_uniqueness_of :name, :scope => [ :publisher, :year ]
          end

          after do
            Dictionary._validators.clear
            Dictionary._validate_callbacks.clear
          end

          context "when the attribute is unique" do

            before do
              Dictionary.create(:name => "Oxford", :publisher => "Amazon")
            end

            let(:dictionary) do
              Dictionary.new(:name => "Webster")
            end

            it "returns true" do
              dictionary.should be_valid
            end
          end

          context "when the attribute is unique in the scope" do

            before do
              Dictionary.create(
                :name => "Oxford",
                :publisher => "Amazon",
                :year => 2011
              )
            end

            let(:dictionary) do
              Dictionary.new(
                :name => "Webster",
                :publisher => "Amazon",
                :year => 2011
              )
            end

            it "returns true" do
              dictionary.should be_valid
            end
          end

          context "when the attribute is not unique with no scope" do

            before do
              Dictionary.create(:name => "Oxford", :publisher => "Amazon")
            end

            let(:dictionary) do
              Dictionary.new(:name => "Oxford")
            end

            it "returns true" do
              dictionary.should be_valid
            end
          end

          context "when the attribute is not unique in another scope" do

            before do
              Dictionary.create(
                :name => "Oxford",
                :publisher => "Amazon",
                :year => 1995
              )
            end

            let(:dictionary) do
              Dictionary.new(
                :name => "Oxford",
                :publisher => "Addison",
                :year => 2011
              )
            end

            it "returns true" do
              dictionary.should be_valid
            end
          end

          context "when the attribute is not unique in the same scope" do

            context "when the document is not the match" do

              before do
                Dictionary.create(
                  :name => "Oxford",
                  :publisher => "Amazon",
                  :year => 1960
                )
              end

              let(:dictionary) do
                Dictionary.new(
                  :name => "Oxford",
                  :publisher => "Amazon",
                  :year => 1960
                )
              end

              it "returns false" do
                dictionary.should_not be_valid
              end

              it "adds the uniqueness errors" do
                dictionary.valid?
                dictionary.errors[:name].should eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:dictionary) do
                Dictionary.create(
                  :name => "Oxford",
                  :publisher => "Amazon",
                  :year => 1960
                )
              end

              it "returns true" do
                dictionary.should be_valid
              end
            end
          end
        end

        context "when case sensitive is true" do

          before do
            Dictionary.validates_uniqueness_of :name
          end

          after do
            Dictionary._validators.clear
            Dictionary._validate_callbacks.clear
          end

          context "when the attribute is unique" do

            before do
              Dictionary.create(:name => "Oxford")
            end

            let(:dictionary) do
              Dictionary.new(:name => "Webster")
            end

            it "returns true" do
              dictionary.should be_valid
            end
          end

          context "when the attribute is not unique" do

            context "when the document is not the match" do

              before do
                Dictionary.create(:name => "Oxford")
              end

              let(:dictionary) do
                Dictionary.new(:name => "Oxford")
              end

              it "returns false" do
                dictionary.should_not be_valid
              end

              it "adds the uniqueness error" do
                dictionary.valid?
                dictionary.errors[:name].should eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:dictionary) do
                Dictionary.create(:name => "Oxford")
              end

              it "returns true" do
                dictionary.should be_valid
              end
            end
          end
        end

        context "when case sensitive is false" do

          before do
            Dictionary.validates_uniqueness_of :name, :case_sensitive => false
          end

          after do
            Dictionary._validators.clear
            Dictionary._validate_callbacks.clear
          end

          context "when the attribute is unique" do

            context "when there are no special characters" do

              before do
                Dictionary.create(:name => "Oxford")
              end

              let(:dictionary) do
                Dictionary.new(:name => "Webster")
              end

              it "returns true" do
                dictionary.should be_valid
              end
            end

            context "when special characters exist" do

              before do
                Dictionary.create(:name => "Oxford")
              end

              let(:dictionary) do
                Dictionary.new(:name => "Web@st.er")
              end

              it "returns true" do
                dictionary.should be_valid
              end
            end
          end

          context "when the attribute is not unique" do

            context "when the document is not the match" do

              before do
                Dictionary.create(:name => "Oxford")
              end

              let(:dictionary) do
                Dictionary.new(:name => "oxford")
              end

              it "returns false" do
                dictionary.should_not be_valid
              end

              it "adds the uniqueness error" do
                dictionary.valid?
                dictionary.errors[:name].should eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:dictionary) do
                Dictionary.create(:name => "Oxford")
              end

              it "returns true" do
                dictionary.should be_valid
              end
            end
          end
        end

        context "when allowing nil" do

          before do
            Dictionary.validates_uniqueness_of :name, :allow_nil => true
          end

          after do
            Dictionary._validators.clear
            Dictionary._validate_callbacks.clear
          end

          context "when the attribute is nil" do

            before do
              Dictionary.create
            end

            let(:dictionary) do
              Dictionary.new
            end

            it "returns true" do
              dictionary.should be_valid
            end
          end
        end

        context "when allowing blank" do

          before do
            Dictionary.validates_uniqueness_of :name, :allow_blank => true
          end

          after do
            Dictionary._validators.clear
            Dictionary._validate_callbacks.clear
          end

          context "when the attribute is blank" do

            before do
              Dictionary.create(:name => "")
            end

            let(:dictionary) do
              Dictionary.new(:name => "")
            end

            it "returns true" do
              dictionary.should be_valid
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
            Login._validators.clear
            Login._validate_callbacks.clear
          end

          context "when the attribute is unique" do

            before do
              Login.create(:username => "Oxford")
            end

            let(:login) do
              Login.new(:username => "Webster")
            end

            it "returns true" do
              login.should be_valid
            end
          end

          context "when the attribute is not unique" do

            context "when the document is not the match" do

              before do
                Login.create(:username => "Oxford")
              end

              let(:login) do
                Login.new(:username => "Oxford")
              end

              it "returns false" do
                login.should_not be_valid
              end

              it "adds the uniqueness error" do
                login.valid?
                login.errors[:username].should eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:login) do
                Login.create(:username => "Oxford")
              end

              it "returns true" do
                login.should be_valid
              end
            end
          end
        end

        context "when a single scope is provided" do

          before do
            Login.validates_uniqueness_of :username, :scope => :application_id
          end

          after do
            Login._validators.clear
            Login._validate_callbacks.clear
          end

          context "when the attribute is unique" do

            before do
              Login.create(:username => "Oxford", :application_id => 1)
            end

            let(:login) do
              Login.new(:username => "Webster")
            end

            it "returns true" do
              login.should be_valid
            end
          end

          context "when the attribute is unique in the scope" do

            before do
              Login.create(:username => "Oxford", :application_id => 1)
            end

            let(:login) do
              Login.new(:username => "Webster", :application_id => 1)
            end

            it "returns true" do
              login.should be_valid
            end
          end

          context "when the attribute is not unique with no scope" do

            before do
              Login.create(:username => "Oxford", :application_id => 1)
            end

            let(:login) do
              Login.new(:username => "Oxford")
            end

            it "returns false" do
              login.should_not be_valid
            end

            it "adds the uniqueness errors" do
              login.valid?
              login.errors[:username].should eq([ "is already taken" ])
            end
          end

          context "when the attribute is not unique in another scope" do

            before do
              Login.create(:username => "Oxford", :application_id => 1)
            end

            let(:login) do
              Login.new(:username => "Oxford", :application_id => 2)
            end

            it "returns false" do
              login.should_not be_valid
            end

            it "adds the uniqueness errors" do
              login.valid?
              login.errors[:username].should eq([ "is already taken" ])
            end
          end

          context "when the attribute is not unique in the same scope" do

            context "when the document is not the match" do

              before do
                Login.create(:username => "Oxford", :application_id => 1)
              end

              let(:login) do
                Login.new(:username => "Oxford", :application_id => 1)
              end

              it "returns false" do
                login.should_not be_valid
              end

              it "adds the uniqueness errors" do
                login.valid?
                login.errors[:username].should eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:login) do
                Login.create(:username => "Oxford", :application_id => 1)
              end

              it "returns true" do
                login.should be_valid
              end
            end
          end
        end

        context "when case sensitive is true" do

          before do
            Login.validates_uniqueness_of :username
          end

          after do
            Login._validators.clear
            Login._validate_callbacks.clear
          end

          context "when the attribute is unique" do

            before do
              Login.create(:username => "Oxford")
            end

            let(:login) do
              Login.new(:username => "Webster")
            end

            it "returns true" do
              login.should be_valid
            end
          end

          context "when the attribute is not unique" do

            context "when the document is not the match" do

              before do
                Login.create(:username => "Oxford")
              end

              let(:login) do
                Login.new(:username => "Oxford")
              end

              it "returns false" do
                login.should_not be_valid
              end

              it "adds the uniqueness error" do
                login.valid?
                login.errors[:username].should eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:login) do
                Login.create(:username => "Oxford")
              end

              it "returns true" do
                login.should be_valid
              end
            end
          end
        end

        context "when case sensitive is false" do

          before do
            Login.validates_uniqueness_of :username, :case_sensitive => false
          end

          after do
            Login._validators.clear
            Login._validate_callbacks.clear
          end

          context "when the attribute is unique" do

            context "when there are no special characters" do

              before do
                Login.create(:username => "Oxford")
              end

              let(:login) do
                Login.new(:username => "Webster")
              end

              it "returns true" do
                login.should be_valid
              end
            end

            context "when special characters exist" do

              before do
                Login.create(:username => "Oxford")
              end

              let(:login) do
                Login.new(:username => "Web@st.er")
              end

              it "returns true" do
                login.should be_valid
              end
            end
          end

          context "when the attribute is not unique" do

            context "when the document is not the match" do

              before do
                Login.create(:username => "Oxford")
              end

              let(:login) do
                Login.new(:username => "oxford")
              end

              it "returns false" do
                login.should_not be_valid
              end

              it "adds the uniqueness error" do
                login.valid?
                login.errors[:username].should eq([ "is already taken" ])
              end
            end

            context "when the document is the match in the database" do

              let!(:login) do
                Login.create(:username => "Oxford")
              end

              it "returns true" do
                login.should be_valid
              end
            end
          end
        end

        context "when allowing nil" do

          before do
            Login.validates_uniqueness_of :username, :allow_nil => true
          end

          after do
            Login._validators.clear
            Login._validate_callbacks.clear
          end

          context "when the attribute is nil" do

            before do
              Login.create
            end

            let(:login) do
              Login.new
            end

            it "returns true" do
              login.should be_valid
            end
          end
        end

        context "when allowing blank" do

          before do
            Login.validates_uniqueness_of :username, :allow_blank => true
          end

          after do
            Login._validators.clear
            Login._validate_callbacks.clear
          end

          context "when the attribute is blank" do

            before do
              Login.create(:username => "")
            end

            let(:login) do
              Login.new(:username => "")
            end

            it "returns true" do
              login.should be_valid
            end
          end
        end
      end
    end
  end

  context "when the document is embedded" do

    let(:word) do
      Word.create(:name => "Schadenfreude")
    end

    context "when in an embeds_many" do

      context "when no scope is provided" do

        before do
          Definition.validates_uniqueness_of :description
        end

        after do
          Definition._validators.clear
          Definition._validate_callbacks.clear
        end

        context "when the attribute is unique" do

          before do
            word.definitions.build(:description => "Malicious joy")
          end

          let(:definition) do
            word.definitions.build(:description => "Gloating")
          end

          it "returns true" do
            definition.should be_valid
          end
        end

        context "when the attribute is not unique" do

          context "when the document is not the match" do

            before do
              word.definitions.build(:description => "Malicious joy")
            end

            let(:definition) do
              word.definitions.build(:description => "Malicious joy")
            end

            it "returns false" do
              definition.should_not be_valid
            end

            it "adds the uniqueness error" do
              definition.valid?
              definition.errors[:description].should eq([ "is already taken" ])
            end
          end

          context "when the document is the match in the database" do

            let!(:definition) do
              word.definitions.build(:description => "Malicious joy")
            end

            it "returns true" do
              definition.should be_valid
            end
          end
        end
      end

      context "when a single scope is provided" do

        before do
          Definition.validates_uniqueness_of :description, :scope => :part
        end

        after do
          Definition._validators.clear
          Definition._validate_callbacks.clear
        end

        context "when the attribute is unique" do

          before do
            word.definitions.build(
              :description => "Malicious joy", :part => "Noun"
            )
          end

          let(:definition) do
            word.definitions.build(:description => "Gloating")
          end

          it "returns true" do
            definition.should be_valid
          end
        end

        context "when the attribute is unique in the scope" do

          before do
            word.definitions.build(
              :description => "Malicious joy",
              :part => "Noun"
            )
          end

          let(:definition) do
            word.definitions.build(
              :description => "Gloating",
              :part => "Noun"
            )
          end

          it "returns true" do
            definition.should be_valid
          end
        end

        context "when the attribute is not unique with no scope" do

          before do
            word.definitions.build(
              :description => "Malicious joy",
              :part => "Noun"
            )
          end

          let(:definition) do
            word.definitions.build(:description => "Malicious joy")
          end

          it "returns true" do
            definition.should be_valid
          end
        end

        context "when the attribute is not unique in another scope" do

          before do
            word.definitions.build(
              :description => "Malicious joy",
              :part => "Noun"
            )
          end

          let(:definition) do
            word.definitions.build(
              :description => "Malicious joy",
              :part => "Adj"
            )
          end

          it "returns true" do
            definition.should be_valid
          end
        end

        context "when the attribute is not unique in the same scope" do

          context "when the document is not the match" do

            before do
              word.definitions.build(
                :description => "Malicious joy",
                :part => "Noun"
              )
            end

            let(:definition) do
              word.definitions.build(
                :description => "Malicious joy",
                :part => "Noun"
              )
            end

            it "returns false" do
              definition.should_not be_valid
            end

            it "adds the uniqueness errors" do
              definition.valid?
              definition.errors[:description].should eq([ "is already taken" ])
            end
          end

          context "when the document is the match in the database" do

            let!(:definition) do
              word.definitions.build(
                :description => "Malicious joy",
                :part => "Noun"
              )
            end

            it "returns true" do
              definition.should be_valid
            end
          end
        end
      end

      context "when multiple scopes are provided" do

        before do
          Definition.validates_uniqueness_of :description, :scope => [ :part, :regular ]
        end

        after do
          Definition._validators.clear
          Definition._validate_callbacks.clear
        end

        context "when the attribute is unique" do

          before do
            word.definitions.build(
              :description => "Malicious joy",
              :part => "Noun"
            )
          end

          let(:definition) do
            word.definitions.build(:description => "Gloating")
          end

          it "returns true" do
            definition.should be_valid
          end
        end

        context "when the attribute is unique in the scope" do

          before do
            word.definitions.build(
              :description => "Malicious joy",
              :part => "Noun",
              :regular => true
            )
          end

          let(:definition) do
            word.definitions.build(
              :description => "Gloating",
              :part => "Noun",
              :regular => true
            )
          end

          it "returns true" do
            definition.should be_valid
          end
        end

        context "when the attribute is not unique with no scope" do

          before do
            word.definitions.build(
              :description => "Malicious joy",
              :part => "Noun"
            )
          end

          let(:definition) do
            word.definitions.build(:description => "Malicious scope")
          end

          it "returns true" do
            definition.should be_valid
          end
        end

        context "when the attribute is not unique in another scope" do

          before do
            word.definitions.build(
              :description => "Malicious joy",
              :part => "Noun",
              :regular => true
            )
          end

          let(:definition) do
            word.definitions.build(
              :description => "Malicious joy",
              :part => "Adj",
              :regular => true
            )
          end

          it "returns true" do
            definition.should be_valid
          end
        end

        context "when the attribute is not unique in the same scope" do

          context "when the document is not the match" do

            before do
              word.definitions.build(
                :description => "Malicious joy",
                :part => "Noun",
                :regular => true
              )
            end

            let(:definition) do
              word.definitions.build(
                :description => "Malicious joy",
                :part => "Noun",
                :regular => true
              )
            end

            it "returns false" do
              definition.should_not be_valid
            end

            it "adds the uniqueness errors" do
              definition.valid?
              definition.errors[:description].should eq([ "is already taken" ])
            end
          end

          context "when the document is the match in the database" do

            let!(:definition) do
              word.definitions.build(
                :description => "Malicious joy",
                :part => "Noun",
                :regular => false
              )
            end

            it "returns true" do
              definition.should be_valid
            end
          end
        end
      end

      context "when case sensitive is true" do

        before do
          Definition.validates_uniqueness_of :description
        end

        after do
          Definition._validators.clear
          Definition._validate_callbacks.clear
        end

        context "when the attribute is unique" do

          before do
            word.definitions.build(:description => "Malicious jo")
          end

          let(:definition) do
            word.definitions.build(:description => "Gloating")
          end

          it "returns true" do
            definition.should be_valid
          end
        end

        context "when the attribute is not unique" do

          context "when the document is not the match" do

            before do
              word.definitions.build(:description => "Malicious joy")
            end

            let(:definition) do
              word.definitions.build(:description => "Malicious joy")
            end

            it "returns false" do
              definition.should_not be_valid
            end

            it "adds the uniqueness error" do
              definition.valid?
              definition.errors[:description].should eq([ "is already taken" ])
            end
          end

          context "when the document is the match in the database" do

            let!(:definition) do
              word.definitions.build(:description => "Malicious joy")
            end

            it "returns true" do
              definition.should be_valid
            end
          end
        end
      end

      context "when case sensitive is false" do

        before do
          Definition.validates_uniqueness_of :description, :case_sensitive => false
        end

        after do
          Definition._validators.clear
          Definition._validate_callbacks.clear
        end

        context "when the attribute is unique" do

          context "when there are no special characters" do

            before do
              word.definitions.build(:description => "Malicious joy")
            end

            let(:definition) do
              word.definitions.build(:description => "Gloating")
            end

            it "returns true" do
              definition.should be_valid
            end
          end

          context "when special characters exist" do

            before do
              word.definitions.build(:description => "Malicious joy")
            end

            let(:definition) do
              word.definitions.build(:description => "M@licious.joy")
            end

            it "returns true" do
              definition.should be_valid
            end
          end
        end

        context "when the attribute is not unique" do

          context "when the document is not the match" do

            before do
              word.definitions.build(:description => "Malicious joy")
            end

            let(:definition) do
              word.definitions.build(:description => "Malicious JOY")
            end

            it "returns false" do
              definition.should_not be_valid
            end

            it "adds the uniqueness error" do
              definition.valid?
              definition.errors[:description].should eq([ "is already taken" ])
            end
          end

          context "when the document is the match in the database" do

            let!(:definition) do
              word.definitions.build(:description => "Malicious joy")
            end

            it "returns true" do
              definition.should be_valid
            end
          end
        end
      end

      context "when allowing nil" do

        before do
          Definition.validates_uniqueness_of :description, :allow_nil => true
        end

        after do
          Definition._validators.clear
          Definition._validate_callbacks.clear
        end

        context "when the attribute is nil" do

          before do
            word.definitions.build
          end

          let(:definition) do
            word.definitions.build
          end

          it "returns true" do
            definition.should be_valid
          end
        end
      end

      context "when allowing blank" do

        before do
          Definition.validates_uniqueness_of :description, :allow_blank => true
        end

        after do
          Definition._validators.clear
          Definition._validate_callbacks.clear
        end

        context "when the attribute is blank" do

          before do
            word.definitions.build(:description => "")
          end

          let(:definition) do
            word.definitions.build(:description => "")
          end

          it "returns true" do
            definition.should be_valid
          end
        end
      end
    end

    context "when in an embeds_one" do

      before do
        Pronunciation.validates_uniqueness_of :sound
      end

      after do
        Pronunciation._validators.clear
        Pronunciation._validate_callbacks.clear
      end

      let(:pronunciation) do
        word.build_pronunciation(:sound => "Schwa")
      end

      it "always returns true" do
        pronunciation.should be_valid
      end
    end
  end
end
