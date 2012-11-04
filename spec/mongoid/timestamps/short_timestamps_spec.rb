require "spec_helper"

class DokumentWithShortTimestamps
  include Mongoid::Document
  include Mongoid::ShortTimestamps
end

describe Mongoid::ShortTimestamps do

  let(:document) { DokumentWithShortTimestamps.new }

  let(:fields) { document.fields }

  before do
    document.run_callbacks :create
    document.run_callbacks :save
  end

  it "adds c_at to the document" do
    fields["c_at"].should_not be_nil
  end

  it "doesn't add a created_at to the document" do
    fields["created_at"].should be_nil
  end

  it "adds u_at to the document" do
    fields["u_at"].should_not be_nil
  end

  it "can access c_at with created_at alias" do
    document.created_at.should_not be_nil
  end

  it "can access u_at with updated_at alias" do
    document.updated_at.should_not be_nil
  end

end
