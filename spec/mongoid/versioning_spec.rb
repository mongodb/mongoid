require "spec_helper"

describe Mongoid::Versioning do

  describe ".max_versions" do

    context "when provided an integer" do

      before do
        WikiPage.max_versions(10)
      end

      after do
        WikiPage.max_versions(5)
      end

      it "sets the class version max" do
        WikiPage.version_max.should eq(10)
      end
    end

    context "when provided a string" do

      before do
        WikiPage.max_versions("10")
      end

      after do
        WikiPage.max_versions(5)
      end

      it "sets the class version max" do
        WikiPage.version_max.should eq(10)
      end
    end
  end

  # describe "#version" do

    # context "when there is no default scope" do

      # context "when the document is new" do

        # it "returns 1" do
          # WikiPage.new.version.should eq(1)
        # end
      # end

      # context "when the document is persisted once" do

        # let(:page) do
          # WikiPage.create(title: "1")
        # end

        # it "returns 1" do
          # page.version.should eq(1)
        # end
      # end

      # context "when the document is persisted more than once" do

        # let(:page) do
          # WikiPage.create(title: "1")
        # end

        # before do
          # 3.times { |n| page.update_attribute(:title, "#{n}") }
        # end

        # it "returns the number of versions" do
          # page.version.should eq(4)
        # end
      # end

      # context "when maximum versions is defined" do

        # let(:page) do
          # WikiPage.create(title: "1")
        # end

        # context "when saving over the max versions limit" do

          # before do
            # 10.times { |n| page.update_attribute(:title, "#{n}") }
          # end

          # it "returns the number of versions" do
            # page.version.should eq(11)
          # end
        # end
      # end

      # context "when performing versionless saves" do

        # let(:page) do
          # WikiPage.create(title: "1")
        # end

        # before do
          # 10.times do |n|
            # page.versionless { |doc| doc.update_attribute(:title, "#{n}") }
          # end
        # end

        # it "does not increment the version number" do
          # page.version.should eq(1)
        # end
      # end
    # end

    # context "when there is a default scope" do

      # before :all do
        # class WikiPage
          # default_scope where(author: "Jim")
        # end
      # end

      # after :all do
        # WikiPage.default_scoping.clear
      # end

      # context "when the document is new" do

        # it "returns 1" do
          # WikiPage.new.version.should eq(1)
        # end
      # end

      # context "when the document is persisted once" do

        # let(:page) do
          # WikiPage.create(title: "1")
        # end

        # it "returns 1" do
          # page.version.should eq(1)
        # end
      # end

      # context "when the document is persisted more than once" do

        # let(:page) do
          # WikiPage.create(title: "1")
        # end

        # before do
          # 3.times { |n| page.update_attribute(:title, "#{n}") }
        # end

        # it "returns the number of versions" do
          # page.version.should eq(4)
        # end
      # end

      # context "when maximum versions is defined" do

        # let(:page) do
          # WikiPage.create(title: "1")
        # end

        # context "when saving over the max versions limit" do

          # before do
            # 10.times { |n| page.update_attribute(:title, "#{n}") }
          # end

          # it "returns the number of versions" do
            # page.version.should eq(11)
          # end
        # end
      # end

      # context "when performing versionless saves" do

        # let(:page) do
          # WikiPage.create(title: "1")
        # end

        # before do
          # 10.times do |n|
            # page.versionless { |doc| doc.update_attribute(:title, "#{n}") }
          # end
        # end

        # it "does not increment the version number" do
          # page.version.should eq(1)
        # end
      # end
    # end
  # end

  describe "#versionless" do

    let(:page) do
      WikiPage.new(created_at: Time.now.utc)
    end

    context "when executing the block" do

      it "sets versionless to true" do
        page.versionless do |doc|
          doc.should be_versionless
        end
      end
    end

    context "when the block finishes" do

      it "sets versionless to false" do
        page.versionless
        page.should_not be_versionless
      end
    end
  end

  describe "#versions" do

    let(:page) do
      WikiPage.create(title: "1") do |wiki|
        wiki.author = "woodchuck"
      end
    end

    context "when saving the document " do

      context "when the document has changed" do

        before do
          page.update_attribute(:title, "2")
        end

        let(:version) do
          page.versions.first
        end

        it "creates a new version" do
          version.title.should eq("1")
        end

        it "only creates 1 new version" do
          page.versions.count.should eq(1)
        end

        it "does not version the _id" do
          version._id.should be_nil
        end

        it "does version the updated_at timestamp" do
          version.updated_at.should_not be_nil
        end

        context "when only updated_at was changed" do

          before do
            page.update_attributes(updated_at: Time.now)
          end

          it "does not generate another version" do
            page.versions.count.should eq(1)
          end
        end

        it "does not embed versions within versions" do
          version.versions.should be_empty
        end

        it "versions protected fields" do
          version.author.should eq("woodchuck")
        end

        context "when saving multiple times" do

          before do
            page.update_attribute(:title, "3")
          end

          it "does not embed versions within versions" do
            version.versions.should be_empty
          end

          it "does not embed versions multiple levels deep" do
            page.versions.last.versions.should be_empty
          end
        end
      end

      context "when the document has not changed" do

        before do
          page.save
        end

        let(:version) do
          page.versions.first
        end

        it "does not create a new version" do
          version.should be_nil
        end
      end

      context "when saving over the number of maximum versions" do

        context "when the document is paranoid" do

          let!(:post) do
            ParanoidPost.create(title: "test")
          end

          before do
            3.times do |n|
              post.update_attribute(:title, "#{n}")
            end
          end

          it "only versions the maximum amount" do
            post.versions.target.size.should eq(2)
          end

          it "persists the changes" do
            post.reload.versions.target.size.should eq(2)
          end
        end

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
                WikiPage.find(page.id).update_attributes(title: "#{n}")
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

      context "when persisting versionless" do

        before do
          page.versionless { |doc| doc.update_attribute(:title, "2") }
        end

        it "does not version the document" do
          page.versions.count.should eq(0)
        end
      end

      context "when deleting versions" do

        let(:comment) do
          Comment.new(title: "Don't delete me!")
        end

        let!(:orphaned) do
          Comment.create(title: "Annie")
        end

        before do
          page.comments << comment
          page.update_attribute(:title, "5")
        end

        context "when the version had a dependent relation" do

          before do
            page.versions.delete_all
          end

          let(:from_db) do
            Comment.find(comment.id)
          end

          it "does not perform dependent cascading" do
            from_db.should eq(comment)
          end

          it "does not delete related orphans" do
            Comment.find(orphaned.id).should eq(orphaned)
          end

          it "deletes the version" do
            page.versions.should be_empty
          end

          it "persists the deletion" do
            page.reload.versions.should be_empty
          end

          it "retains the root relation" do
            page.reload.comments.should eq([ comment ])
          end
        end
      end
    end
  end

  context "when appending a self referencing document with versions" do

    let(:page) do
      WikiPage.create(title: "1")
    end

    let(:child) do
      WikiPage.new
    end

    before do
      page.child_pages << child
    end

    it "allows the document to be added" do
      page.child_pages.should eq([ child ])
    end

    it "persists the changes" do
      page.reload.child_pages.should eq([ child ])
    end
  end

  context "when the identity map is enabled" do

    before do
      Mongoid.identity_map_enabled = true
    end

    after do
      Mongoid.identity_map_enabled = false
    end

    context "when updating a loaded attribute" do

      let!(:page) do
        WikiPage.create(title: "first")
      end

      let!(:loaded) do
        WikiPage.find(page.id)
      end

      before do
        loaded.update_attribute(:title, "revised")
      end

      let(:reloaded) do
        WikiPage.find(page.id)
      end

      it "returns the revised im memory document" do
        reloaded.title.should eq("revised")
      end
    end
  end
end
