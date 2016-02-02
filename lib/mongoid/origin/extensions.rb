# encoding: utf-8
unless defined?(Boolean)
  class Boolean; end
end

if defined?(ActiveSupport)
  unless defined?(ActiveSupport::TimeWithZone)
    require "active_support/time_with_zone"
  end
  require "mongoid/origin/extensions/time_with_zone"
end

require "time"
require "mongoid/origin/extensions/object"
require "mongoid/origin/extensions/array"
require "mongoid/origin/extensions/big_decimal"
require "mongoid/origin/extensions/boolean"
require "mongoid/origin/extensions/date"
require "mongoid/origin/extensions/date_time"
require "mongoid/origin/extensions/hash"
require "mongoid/origin/extensions/nil_class"
require "mongoid/origin/extensions/numeric"
require "mongoid/origin/extensions/range"
require "mongoid/origin/extensions/regexp"
require "mongoid/origin/extensions/set"
require "mongoid/origin/extensions/string"
require "mongoid/origin/extensions/symbol"
require "mongoid/origin/extensions/time"
