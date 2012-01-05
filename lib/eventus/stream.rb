module Eventus
  class Stream

    attr_accessor :id, :committed_events, :uncommitted_events

    def initialize(id, events)
      @id = id
      @committed_events = events
      @uncommitted_events = []
    end

    def <<(event)
      @uncommitted_events << event
    end
  end
end
