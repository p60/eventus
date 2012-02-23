require 'kyotocabinet'

module Eventus
  module Persistence
    class KyotoCabinet

      def initialize(options = {})
        @db = ::KyotoCabinet::DB::new
        @queue = ::KyotoCabinet::DB::new
        @serializer = options.delete(:serializer) || Eventus::Serializers::Marshal
        queue_con = build_connection(:path => options.delete(:queue_path) || '*')
        con = build_connection(options)
        Eventus.logger.info "Opening db: #{con}, queue: #{queue_con}"
        raise Eventus::ConnectionError unless @db.open(con) && @queue.open(queue_con)
      end

      def commit(events)
        @db.transaction do
          events.each do |event, index|
            pid = pack_hex(event['sid'])
            key = build_key(pid, event['sequence'])
            value = @serializer.serialize(event)
            raise Eventus::ConcurrencyError unless @db.add(key,value)
            @queue.set(key, "")
          end
        end
        events
      end

      def load(id, min = nil)
        Eventus.logger.debug "Loading stream: #{id}"
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
        @queue.each_key do |key|
          value = @db.get(key[0])
          next unless value
          obj = @serializer.deserialize(value)
          events << obj
        end
        Eventus.logger.info "#{events.length} undispatched events loaded"
        events
      end

      def mark_dispatched(stream_id, sequence)
        Eventus.logger.debug "Marking #{stream_id}_#{sequence} dispatched"
        key = build_key(pack_hex(stream_id), sequence)
        @queue.remove(key)
      end

      def pack_hex(id)
        id.match(/^[0-9a-fA-F]+$/) ? [id].pack('H*') : id
      end

      def build_key(id, index)
        id + ("_%07d" % index)
      end

      def close
        @db.close
        @queue.close
      end

      private

      def build_connection(options)
        opts = {
          :path => '%', #in-memory tree
          :opts => :linear
        }.merge!(options)

        path = opts.delete(:path)

        opts.reduce(path) { |memo, kvp| memo << "##{kvp[0]}=#{kvp[1]}" }
      end
    end
  end
end
