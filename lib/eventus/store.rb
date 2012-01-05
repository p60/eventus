module Eventus
  class Store

    def initialize(persistence)
      @persistence = persistence
    end

    def open id
      @persistence.get_events(id)
    end
  end
end
