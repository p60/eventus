module Eventus
  module Persistence
    class InMemory

      def initialize(options = {})
        @store = {}
        @serializer = options.fetch(:serializer) { Eventus::Serializers::Marshal }
        @mutex = Mutex.new
      end

      def commit(id, start, events)
        @mutex.synchronize do
          pending = {}
          events.each_with_index do |event, index|
            key = build_key(id, start + index)
            raise Eventus::ConcurrencyError if @store.include? key
            value = @serializer.serialize(event)
            pending[key] = value
          end
          @store.merge! pending
        end
      end

      def load(id, min=nil)
        @mutex.synchronize do
          keys = @store.keys.select { |k| k.start_with? id }.sort

          if min
            min_key = build_key(id, min)
            keys = keys.drop_while { |k| k != min_key }
          end

          keys.map { |k| @serializer.deserialize(@store[k]) }
        end
      end

      def load_undispatched
        @mutex.synchronize do
          @store.map { |k,v| build_event(k, @serializer.deserialize(v)) }
                .reject { |e| e['dispatched'] || e[:dispatched] }
        end
      end

      def build_key(id, index)
        id + ("_%07d" % index)
      end


      private
      def build_event(key, body)
        body['event_id'] = key
        body
      end
    end
  end
end
