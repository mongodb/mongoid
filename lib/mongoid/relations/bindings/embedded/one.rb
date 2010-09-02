# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Bindings #:nodoc:
      module Embedded #:nodoc:
        class One < Binding

          def bind
            # if embedded_bindable?(base)
              # target.send(metadata.inverse_setter(target), base)
            # end
          end

          def unbind
            # if embedded_unbindable?(target)
              # target.send(metadata.inverse_setter(target), nil)
            # end
          end
        end
      end
    end
  end
end
