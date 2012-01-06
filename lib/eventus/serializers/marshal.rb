module Eventus
  module Serializers
    module Marshal
      class << self
        def serialize(obj)
          ::Marshal.dump obj
        end

        def deserialize(obj)
          ::Marshal.load obj
        end
      end
    end
  end
end
