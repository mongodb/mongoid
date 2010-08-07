# encoding: utf-8
require "mongoid/relations/accessors"
require "mongoid/relations/proxy"
require "mongoid/relations/embedded/in"
require "mongoid/relations/embedded/many"
require "mongoid/relations/embedded/one"
require "mongoid/relations/metadata"
require "mongoid/relations/macros"

module Mongoid # :nodoc:
  module Relations #:nodoc:
    extend ActiveSupport::Concern
    include Accessors
    include Macros
  end
end
