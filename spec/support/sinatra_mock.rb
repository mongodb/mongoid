# rubocop:todo all
module Sinatra
  module Base
    extend self
    def environment; :staging; end
  end
end
