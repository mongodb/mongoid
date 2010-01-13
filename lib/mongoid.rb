# encoding: utf-8
# Copyright (c) 2009 Durran Jordan
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
require "rubygems"

gem "activesupport", ">= 2.2.2"
gem "mongo", ">= 0.18.2"
gem "durran-validatable", ">= 2.0.1"
gem "leshill-will_paginate", ">= 2.3.11"

require "delegate"
require "observer"
require "singleton"
require "time"
require "validatable"
require "active_support/callbacks"
require "active_support/core_ext"
require "active_support/inflector"
require "active_support/time_with_zone"
require "will_paginate/collection"
require "mongo"
require "mongoid/associations"
require "mongoid/associations/options"
require "mongoid/attributes"
require "mongoid/callbacks"
require "mongoid/commands"
require "mongoid/config"
require "mongoid/complex_criterion"
require "mongoid/criteria"
require "mongoid/extensions"
require "mongoid/errors"
require "mongoid/field"
require "mongoid/fields"
require "mongoid/finders"
require "mongoid/identity"
require "mongoid/indexes"
require "mongoid/memoization"
require "mongoid/named_scope"
require "mongoid/scope"
require "mongoid/timestamps"
require "mongoid/versioning"
require "mongoid/components"
require "mongoid/document"

module Mongoid #:nodoc

  class << self
    #direct all calls to the configuration
    def method_missing(name, *args)
      Config.instance.send(name, *args)
    end
  end

end
