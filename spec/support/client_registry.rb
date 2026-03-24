require 'singleton'

class ClientRegistry
  include Singleton

  def global_client(_name)
    Mongoid.default_client
  end
end
