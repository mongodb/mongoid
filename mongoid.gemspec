# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require "mongoid/version"

Gem::Specification.new do |s|
  s.name        = "mongoid"
  s.version     = Mongoid::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Durran Jordan"]
  s.email       = ["durran@gmail.com"]
  s.homepage    = "http://mongoid.org"
  s.summary     = "Elegent Persistance in Ruby for MongoDB."
  s.description = "Mongoid is an ODM (Object Document Mapper) Framework for MongoDB, written in Ruby."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "mongoid"

  s.add_dependency("activemodel", ["= 3.0.0.rc"])
  s.add_dependency("tzinfo", ["= 0.3.22"])
  s.add_dependency("will_paginate", ["~>3.0.pre"])
  s.add_dependency("mongo", ["= 1.0.6"])
  s.add_dependency("bson", ["= 1.0.4"])

  s.add_development_dependency("bson_ext", ["= 1.0.4"])
  s.add_development_dependency("mocha", ["= 0.9.8"])
  s.add_development_dependency("rspec", ["= 2.0.0.beta.19"])
  s.add_development_dependency("watchr", ["= 0.6"])

  s.files        = Dir.glob("lib/**/*") + %w(MIT_LICENSE README.rdoc)
  s.require_path = 'lib'

  s.post_install_message = <<-POST_INSTALL_MESSAGE
   _________________________________
  |:::::::::::::::::::::::::::::::::| "I find your lack of faith disturbing."
  |:::::::::::::;;::::::::::::::::::|
  |:::::::::::'~||~~~``:::::::::::::| Mongoid 2 introduces
  |::::::::'   .':     o`:::::::::::| a different way of defining how
  |:::::::' oo | |o  o    ::::::::::| ids are stored on documents, as
  |::::::: 8  .'.'    8 o  :::::::::| well as how foreign key fields
  |::::::: 8  | |     8    :::::::::| and indexes are stored.
  |::::::: _._| |_,...8    :::::::::|
  |::::::'~--.   .--. `.   `::::::::| If you were using String
  |:::::'     =8     ~  \\ o ::::::::| representations of BSON::ObjectIDs
  |::::'       8._ 88.   \\ o::::::::| as your document ids, all of your
  |:::'   __. ,.ooo~~.    \\ o`::::::| documents will now need to tell
  |:::   . -. 88`78o/:     \\  `:::::| Mongoid to use Strings like so:
  |::'     /. o o \\ ::      \\88`::::|
  |:;     o|| 8 8 |d.        `8 `:::| class User
  |:.       - ^ ^ -'           `-`::|   include Mongoid::Document
  |::.                          .:::|   identity :type => String
  |:::::.....           ::'     ``::| end
  |::::::::-'`-        88          `|
  |:::::-'.          -       ::     | All ids will default to
  |:-~. . .                   :     | BSON:ObjectIDs from now on, and
  | .. .   ..:   o:8      88o       | Config#use_object_ids has been
  |. .     :::   8:P     d888. . .  | removed.
  |.   .   :88   88      888'  . .  |
  |   o8  d88P . 88   ' d88P   ..   | Foreign key fields for relational
  |  88P  888   d8P   ' 888         | associations no longer index by
  |   8  d88P.'d:8  .- dP~ o8       | default - you will need to pass
  |      888   888    d~ o888    LS | :index => true to the association
  |_________________________________| definition to have the field indexed

  or create the index manually, which is the preferred method. Note that
  if you were using String ids and now want to use object ids instead you
  will have to migrate your database manually - Mongoid cannot perform
  this for you automatically. If you were using custom composite keys,
  these will need to be defined as Strings since they cannot be converted.

  You can run a rake task to convert all your string object ids to ObjectID (thanks to Kyle Banker):

  rake db:mongoid:objectid_convert

  Your old collections will be backed up to their original names appended with "_old".
  If you verify your site is still working good with the ObjectIDs, you can clean them up using:

  rake db:mongoid:cleanup_old_collections

  POST_INSTALL_MESSAGE
end
