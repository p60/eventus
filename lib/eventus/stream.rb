require 'time'

module Eventus
  class Stream

    attr_reader :id, :committed_events, :uncommitted_events

    def initialize(id, persistence, dispatcher)
      @id = id
      @persistence = persistence
      @committed_events = []
      @uncommitted_events = []
      @dispatcher = dispatcher
      load_events @persistence.load(id)
    end

    def add(name, body={})
      @uncommitted_events << {'name' => name, 'body' => body}
    end

    def commit
      time = Time.now.utc.iso8601
      @uncommitted_events.each.with_index(version) do |e, i|
        e['time'] = time
        e['sid'] = @id
        e['sequence'] = i
      end
      @persistence.commit @uncommitted_events
      load_events @uncommitted_events
      @dispatcher.dispatch @uncommitted_events if @dispatcher
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
