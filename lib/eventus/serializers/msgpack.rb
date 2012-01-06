require 'msgpack'

module Eventus
  module Serializers
    module MessagePack
      class << self
        def serialize(obj)
          ::MessagePack.pack(obj)
        end

        def deserialize(obj)
          ::MessagePack.unpack(obj)
        end
      end
    end
  end
end
