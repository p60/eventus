module Eventus
  module Dispatchers
    class Synchronous
      attr_accessor :action

      def initialize(persistence, &block)
        @persistence = persistence
        @action = block || lambda {}
      end

      def dispatch(events)
        Eventus.logger.info "Dispatching #{events.length} events"
        events.each do |e|
          @action.call(e)
          @persistence.mark_dispatched e
        end
      end
    end
  end
end
