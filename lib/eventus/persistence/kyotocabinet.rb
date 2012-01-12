require 'kyotocabinet'

module Eventus
  module Persistence
    class KyotoCabinet

      def initialize(options = {})
        @db = ::KyotoCabinet::DB::new
        @db.open(options[:path], ::KyotoCabinet::DB::OCREATE)
        @serializer = options.fetch(:serializer) { Eventus::Serializers::Marshal }
      end

      def commit(events)
        @db.transaction do
          events.each do |event, index|
            pid = pack_hex(event['sid'])
            key = build_key(pid, event['sequence'])
            value = @serializer.serialize(event)
            raise Eventus::ConcurrencyError unless @db.add(key,value)
          end
        end
      end

      def load(id, min = nil)
        pid = pack_hex(id)
        keys = @db.match_prefix(pid)

        if min
          min_key = build_key(pid, min)
          keys = keys.drop_while { |k| k != min_key }
        end

        @db.get_bulk(keys, false).values.map { |obj| @serializer.deserialize(obj) }
      end

      def load_undispatched
        events = []
        @db.cursor_process do |cur|
          cur.jump
          while (record = cur.get(true))
            k,v = record
            obj = @serializer.deserialize(v)
            unless (obj['dispatched'] || obj[:dispatched])
              events << obj
            end
          end
        end

        events
      end

      def pack_hex(id)
        id.match(/^[0-9a-fA-F]+$/) ? [id].pack('H*') : id
      end

      def build_key(id, index)
        id + ("_%07d" % index)
      end
    end
  end
end
