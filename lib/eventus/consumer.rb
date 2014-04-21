module Eventus
  module Consumer
    module ClassMethods
      def apply(event_name, &block)
        raise "A block is required" unless block_given?
        define_method("apply_#{event_name}", &block)
      end
    end

    module InstanceMethods
      def populate(events)
        if events.respond_to? :committed_events
          @stream = events
          events = events.committed_events
        end

        events.each do |event|
          apply_change event['name'], event['body'], false
        end
      end

      protected

      def apply_change(name, body=nil, is_new=true)
        method_name = "apply_#{name}"
        self.send method_name, body if self.respond_to?(method_name)

        @stream.add(name, body) if @stream && is_new
      end
    end

    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end
  end
end
