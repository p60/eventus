module Eventus
  class Stream

    attr_accessor :id, :committed_events, :uncommitted_events

    def initialize(id, events)
      @id = id
      @committed_events = events
      @uncommitted_events = []
    end

    def add(event)
      @uncommitted_events << event
    end

    alias_method :<<, :add

    def commit
      @uncommitted_events.each{ |u| @committed_events << u }
      @uncommitted_events.clear
    end
  end
end
