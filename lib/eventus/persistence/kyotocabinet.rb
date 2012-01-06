require 'kyotocabinet'

module Eventus
  module Persistence
    class KyotoCabinet

      def initialize(options = {})
        @db = ::KyotoCabinet::DB::new
        @db.open(options[:path], ::KyotoCabinet::DB::OCREATE)
        @serializer = options.fetch(:serializer, Eventus::Serializers::Marshal)
      end

      def commit(id, start, events)
        pid = packed(id)
        @db.transaction do
          events.each_with_index do |event,index|
            key = build_key(pid, start + index)
            value = @serializer.serialize(event)
            raise Eventus::ConcurrencyError unless @db.add(key,value)
          end
        end
      end

      def load(id)
        pid = packed(id)
        keys = @db.match_prefix(pid)
        @db.get_bulk(keys,false).values.map { |obj| @serializer.deserialize(obj) }
      end

      def packed(id)
        [id].pack('H*')
      end

      def build_key(id, index)
        id + ("_%07d" % index)
      end
    end
  end
end
