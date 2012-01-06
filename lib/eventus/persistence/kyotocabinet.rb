module Eventus
  module Persistence
    class KyotoCabinet

      def initialize(options = {})
        @db = ::KyotoCabinet::DB::new
        @db.open(options[:path], ::KyotoCabinet::DB::OCREATE)
      end

      def commit(id, start, events)
        pid = packed(id)
        @db.transaction do
          events.each_with_index do |event,index|
            key = build_key(pid, start + index)
            raise ConcurrencyError unless @db.add(key,event)
          end
        end
      end

      def load(id)
        pid = packed(id)
        keys = @db.match_prefix(pid)
        @db.get_bulk(keys,false)
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
