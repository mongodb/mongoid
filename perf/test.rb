require "mongoid"

Mongoid.configure do |config|
  config.master = Mongo::Connection.new.db("mongoid_perf_test")
end

Mongoid.master.collections.select {|c| c.name !~ /system/ }.each(&:remove)

class User
  include Mongoid::Document
  has_and_belongs_to_many :sites, :autosave => true
end

class Site
  include Mongoid::Document
  has_and_belongs_to_many :users, :autosave => true
end

@site = Site.create()
@user = @site.users.new()
p @site
p @user
p "----"
@user.save

p Site.last
p User.last
