require "spec_helper"

describe Mongoid::Versioning do

  before(:all) do
    WikiPage.delete_all
  end

  describe "#version" do

    let(:page) do
      WikiPage.new(:title => "1")
    end

    context "when the document is new" do

      it "defaults to 1" do
        page.version.should == 1
      end
    end

    context "after the document's first save" do

      before do
        page.save
      end

      it "returns 1" do
        page.version.should == 1
      end
    end

    context "when saving multiple times" do

      it "increments the version by 1" do
        3.times do |n|
          page.update_attribute(:title, "#{n}")
          page.version.should == n + 1
        end
      end
    end

    context "when skipping versioning" do

      it "does not version" do
        3.times do |n|
          page.versionless do |doc|
            doc.update_attribute(:title, "#{n}")
          end
        end
        page.version.should == 1
      end
    end
  end

  describe "#versions" do

    let(:page) do
      WikiPage.create(:title => "1")
    end

    context "when version is less than the maximum" do

      before do
        4.times do |n|
          page.title = "#{n + 2}"
          page.save
        end
      end

      let(:expected) do
        [ "1", "2", "3", "4" ]
      end

      it "retains all versions" do
        page.versions.size.should == 4
      end

      it "retains the correct values" do
        page.versions.map(&:title).should == expected
      end
    end

    context "when version is over the maximum" do

      before do
        7.times do |n|
          page.title = "#{n + 2}"
          page.save
        end
      end

      let(:expected) do
        [ "3", "4", "5", "6", "7" ]
      end

      context "when saving over the number of maximum versions" do

        context "when saving in succession" do

          before do
            10.times do |n|
              page.update_attribute(:title, "#{n}")
            end
          end

          let(:versions) do
            page.versions
          end

          it "only versions the maximum amount" do
            versions.count.should eq(5)
          end

          it "shifts the versions in order" do
            versions.last.title.should eq("8")
          end

          it "persists the version shifts" do
            page.reload.versions.last.title.should eq("8")
          end
        end

        context "when saving in batches" do

          before do
            2.times do
              5.times do |n|
                WikiPage.find(page.id).update_attributes(:title => "#{n}")
              end
            end
          end

          let(:from_db) do
            WikiPage.find(page.id)
          end

          let(:versions) do
            from_db.versions
          end

          it "only versions the maximum amount" do
            versions.count.should eq(5)
          end
        end
      end

      it "retains the set number of most recent versions" do
        page.versions.size.should == 5
      end

      it "retains the most recent values" do
        page.versions.map(&:title).should == expected
      end
    end

    context "when document is also paranoid" do
      let(:post) do
        ParanoidPost.create(:title => "1")
      end

      context "when version is over the maximum" do
        before do
          7.times do |n|
            post.title = "#{n + 2}"
            post.save
          end
        end

        let(:expected) do
          [ "3", "4", "5", "6", "7" ]
        end

        context "when saving over the number of maximum versions" do

          context "when saving in succession" do

            before do
              10.times do |n|
                post.update_attribute(:title, "#{n}")
              end
            end

            let(:versions) do
              post.versions
            end

            it "only versions the maximum amount" do
              versions.count.should eq(5)
            end

            it "shifts the versions in order" do
              versions.last.title.should eq("8")
            end

            it "persists the version shifts" do
              post.reload.versions.last.title.should eq("8")
            end
          end

          context "when saving in batches" do

            before do
              2.times do
                5.times do |n|
                  ParanoidPost.find(post.id).update_attributes(:title => "#{n}")
                end
              end
            end

            let(:from_db) do
              ParanoidPost.find(post.id)
            end

            let(:versions) do
              from_db.versions
            end

            it "only versions the maximum amount" do
              versions.count.should eq(5)
            end
          end
        end

        it "retains the set number of most recent versions" do
          post.versions.size.should == 5
        end

        it "retains the most recent values" do
          post.versions.map(&:title).should == expected
        end
      end
    end

    it "should not version versions attributes" do
      3.times do |n|
        page.title = "#{n + 2}"
        page.save
      end

      page.versions[1].versions.should == []
      page.versions[2].versions.should == []
    end
  end
end
