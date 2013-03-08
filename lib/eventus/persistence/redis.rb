require 'json'

module Eventus
  module Persistence
    class Redis
      def initialize(redis)
        @redis = redis
      end

      def load(id)
        raw_events = @redis.zrange id, 0, -1
        raw_events.map { |e| JSON.parse(e) }
      end

      def commit(events)
        @redis.multi do
          events.each do |event|
            @redis.zadd event['sid'], event['sequence'], event.to_json
          end
        end
      end
    end
  end
end
