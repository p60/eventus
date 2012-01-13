module Eventus
  autoload :Serializers, 'eventus/serializers'
  autoload :AggregateRoot, 'eventus/aggregate_root'
  autoload :Dispatchers, 'eventus/dispatchers'
  autoload :Persistence, 'eventus/persistence'
  autoload :VERSION, 'eventus/version'

  class << self

    def persistence
      @persistence ||= Eventus::Persistence::InMemory.new
    end

    def persistence=(val)
      @persistence = val
    end

    def dispatcher
      @dispatcher ||= Eventus::Dispatchers::Synchronous.new(persistence)
    end

    def dispatcher=(val)
      @dispatcher = val
    end
  end
end

%w{stream errors}.each { |r| require "eventus/#{r}" }
