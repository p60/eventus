module Eventus
  class Stream

    attr_reader :id, :committed_events, :uncommitted_events

    def initialize(id, persistence)
      @id = id
      @persistence = persistence
      @committed_events = []
      @uncommitted_events = []
      load_events @persistence.load(id)
    end

    def add(event)
      @uncommitted_events << event
    end

    alias_method :<<, :add

    def commit
      @persistence.commit @id, version, @uncommitted_events
      load_events @uncommitted_events
      @uncommitted_events.clear
    rescue ConcurrencyError => e
      load_events @persistence.load(id, version + 1)
      raise e
    end

    def version
      @committed_events.length
    end

    private

    def load_events(events)
      events.each { |e| @committed_events << e }
    end
  end
end
