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
          @event_conflicts[k.to_s] = v.respond_to?(:map) ? v.map{|e| e.to_s} : v.to_s
        end
      end

      def conflict?(e1, e2)
        return false unless @event_conflicts
        @event_conflicts.fetch(e1,[]).include?(e2) || @event_conflicts.fetch(e2,[]).include?(e1)
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
      rescue Eventus::ConcurrencyError
        committed = @stream.committed_events[version-1..-1]
        uncommitted = @stream.uncommitted_events
        conflict = committed.any?{ |e| uncommitted.any? {|u| self.class.conflict?(e['name'], u['name'])} }
        raise Eventus::ConflictError if conflict
        false
      end

      protected

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
