module Mongoid
  # sloppily define undefined fields to make getting up and running with mongoid even easier.
  module Autofields
    def method_missing(m, *a)
      return super unless m =~ /=/
        return super unless a.size == 1
      meth = m.to_s.gsub('=', '')
      type = a.first.class
      self.class.field meth.to_sym, type: type
      self.send m.to_sym, *a
    end
  end
end
