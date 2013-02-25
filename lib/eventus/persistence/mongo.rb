require 'mongo'

module Eventus
  module Persistence
    class Mongo
      attr_reader :db

      def initialize(uri, options={})
        collection_name = options.delete(:collection) || 'eventus_commits'
        @db = build_db(uri, options)
        @commits = db.collection(collection_name)
      end

      def commit(events)
        return if events.empty?
        seqs = events.map{|e| e['sequence']}
        doc = {
          '_id'        => "#{events[0]['sid']}_#{seqs.min}",
          'sid'        => events[0]['sid'],
          'min'        => seqs.min,
          'max'        => seqs.max,
          'events'     => events,
          'dispatched' => false
        }

        future = @commits.find_one({sid:doc['sid'], max:{:$gte => doc['min']}})
        raise Eventus::ConcurrencyError if future
        begin
        @commits.insert(doc, w: 2)
        rescue ::Mongo::OperationFailure => e
          raise Eventus::ConcurrencyError if e.error_code == 11000
        end
        doc
      end

      def load(id, min = nil)
        Eventus.logger.debug "Loading stream: #{id}"
        query = {sid:id}

        if min
          query[:max] = {:$gte => min}
        end

        min ||= 0

        @commits.find(query).to_a
          .map{|c| c['events']}
          .flatten
          .reject{|e| e['sequence'] < min}
          .sort_by{|e| e['sequence']}
      end

      def load_undispatched_commits
        commits = @commits.find(dispatched:false).to_a
        if commits.length > 0
          Eventus.logger.info "#{commits.length} undispatched commits loaded"
        end
        commits
      end

      def mark_commit_dispatched(commit_id)
        Eventus.logger.debug "Marking commit #{commit_id} dispatched"
        @commits.update({_id: commit_id}, {'$set' => {'dispatched' => true}})
      end

      private

      def build_db(uri, options={})
        parts = URI.parse(uri)
        raise "scheme must be mongodb, found #{parts.scheme}" unless parts.scheme == 'mongodb'
        db = ::Mongo::Connection.new(parts.host, parts.port, options).db(parts.path.gsub(/^\//, ''))
        db.authenticate(parts.user, parts.password) if parts.user && parts.password
        db
      end

    end
  end
end
