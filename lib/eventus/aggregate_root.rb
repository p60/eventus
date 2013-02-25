module Eventus
  module AggregateRoot
    module ClassMethods
      def find(id)
        instance = self.new
        stream = Eventus::Stream.new(id, persistence, Eventus.dispatcher)
        instance.populate(stream)
        instance
      end

      def apply(event_name, &block)
        raise "A block is required" unless block_given?
        define_method("apply_#{event_name}", &block)
      end

      def persistence
        @persistence ||= Eventus.persistence
      end

      def conflicts(added = {})
        @event_conflicts ||= {}
        added.each do |k,v|
          @event_conflicts[k.to_s] = v.respond_to?(:map) ? v.map{|e| e.to_s} : [v.to_s]
        end
      end

      def conflict?(e1, e2)
        return false unless @event_conflicts
        s1 = e1.to_s
        s2 = e2.to_s
        @event_conflicts.fetch(s1,[]).include?(s2) || @event_conflicts.fetch(s2,[]).include?(s1)
      end
    end

    module InstanceMethods
      def populate(stream)
        @stream = stream
        stream.committed_events.each do |event|
          apply_change event['name'], event['body'], false
        end
      end

      def save
        version = @stream.version
        @stream.commit
        true
      rescue Eventus::ConcurrencyError => e
        on_concurrency_error(version, e)
      end

      protected

      def on_concurrency_error(version, e)
        committed = @stream.committed_events.drop(version)
        uncommitted = @stream.uncommitted_events
        conflict = committed.any?{ |e| uncommitted.any? {|u| self.class.conflict?(e['name'], u['name'])} }
        raise Eventus::ConflictError if conflict
        false
      end

      def apply_change(name, body=nil, is_new=true)
        method_name = "apply_#{name}"
        self.send method_name, body if self.respond_to?(method_name)

        @stream.add(name, body) if is_new
      end
    end

    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end
  end
end
