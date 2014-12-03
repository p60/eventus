module Eventus
  module Persistence
    class Sequel
      MIGRATIONS_PATH = File.expand_path('../sequel/migrations', __FILE__).freeze
      TABLE_NAME = :eventus_events

      attr_reader :dataset, :db

      def initialize(db)
        @db = db
        @dataset = db[TABLE_NAME]
        @dataset.row_proc = method :convert_row
      end

      def commit(events)
        @db.transaction(:savepoint => true) do
          events.each do |event|
            event['body'] = db.typecast_value(:json, event['body'] || {})
          end
          @dataset.multi_insert(events)
        end
        events
      rescue ::Sequel::UniqueConstraintViolation
        raise Eventus::ConcurrencyError
      end

      def load(sid, min = nil, max = nil)
        _load(sid, nil, min, max)
      end

      def load_undispatched(sid = nil)
        _load(sid, false)
      end

      def _load(sid = nil, dispatched = nil, min = nil, max = nil)
        events = @dataset
        events = events.where(:sid => sid) unless sid.nil?
        events = events.where(:dispatched => dispatched) unless dispatched.nil?
        events = events.where{ sequence >= min } unless min.nil?
        events = events.where{ sequence <= max } unless max.nil?
        events.order_by(:sequence).all
      end

      def mark_dispatched(sid, sequence)
        @dataset
          .where(:sid => sid, :sequence => sequence)
          .update(:dispatched => true)
      end

      def convert_row(row)
        res = row.each_with_object({}) do |(k,v), memo|
          memo[k.to_s] = v
        end
        res['body'] = res.fetch('body', {}).to_hash
        res
      end

      def self.migrate!(db, target = nil)
        ::Sequel.extension :migration
        ::Sequel::Migrator.run(db, MIGRATIONS_PATH, :target => target, :table => :eventus_schema)
      end
    end
  end
end
