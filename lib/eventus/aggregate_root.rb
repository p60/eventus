module Eventus
  module AggregateRoot
    module ClassMethods
      def find(id)
        instance = self.new
        stream = Eventus::Stream.new(id, persistence)
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
    end

    module InstanceMethods
      def populate(stream)
        @stream = stream
        stream.committed_events.each do |event|
          apply_change event[:name], event[:body], false
        end
      end

      protected

      def apply_change(name, body=nil, is_new=true)
        method_name = "apply_#{name}"
        self.send method_name, body if self.respond_to?(method_name)

        @stream.add({:name => name, :body => body}) if is_new
      end
    end

    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end
  end
end
