require 'json'

module Eventus
  module Persistence
    class Redis
      def initialize(redis)
        @redis = redis
      end

      def load(id, min=1)
        raw_events = @redis.zrange id, min-1, -1
        raw_events.map { |e| JSON.parse(e) }
      end

      def commit(events)
        streamId = events[0]['sid']
        version = events[0]['sequence']
        json_events = events.map{|e| e.to_json}
        run_commit streamId, version, json_events

      rescue ::Redis::CommandError
        raise Eventus::ConcurrencyError
      end

      def run_commit(streamId, version, events)
        @sha ||= @redis.script :load, COMMIT_LUA
        @redis.evalsha(@sha, [streamId], [version] + events)
      end

      COMMIT_LUA = <<-LUA
local streamId = KEYS[1]
local version = tonumber(ARGV[1])

local actualVersion = tonumber(redis.call('zcount', streamId, '-inf', '+inf')) + 1
if actualVersion ~= version then
  return redis.error_reply('conflict')
end

for i=2,#ARGV do
  redis.call('zadd', streamId, version+i-2, ARGV[i])
end

return {'commit', tostring(version)}
      LUA
    end
  end
end
