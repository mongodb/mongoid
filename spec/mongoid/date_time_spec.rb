require 'spec_helper'

describe "Date/Time attributes" do

  context "when a DateTime attribute is updated and persisted" do
    let(:user) do
      user = User.create! :last_login => 2.days.ago
      user.last_login = DateTime.now
      user
    end

    it "should be read for persistance as a UTC Time" do
      user.changes["last_login"].last.class.should == Time
    end

    it "should persist with no exceptions thrown" do
      user.save!
    end
  end

  context "when a Date attribute is persisted" do
    let(:user) do
      user = User.create! :account_expires => 2.years.from_now
      user.account_expires = "2/2/2002".to_date
      user
    end

    it "should be read for persistance as a UTC Time" do
      user.changes["account_expires"].last.class.should == Time
    end

    it "should persist with no exceptions thrown" do
      user.save!
    end
  end

end
