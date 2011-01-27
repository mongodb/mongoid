require "spec_helper"

describe Mongoid::Relations::Builders::Referenced::Many do

  describe "#build" do

    let(:person) do
      Person.new
    end

    context "when no documents found in the database" do

      context "when the ids are empty" do

        it "returns an empty array" do
          person.posts.should be_empty
        end

        context "during initialization" do

          it "returns an empty array" do
            Person.new do |p|
              p.posts.should be_empty
              p.posts.metadata.should_not be_nil
            end
          end
        end
      end
    end
  end
end
