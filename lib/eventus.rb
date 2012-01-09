module Eventus
  autoload :Serializers, 'eventus/serializers'
  autoload :AggregateRoot, 'eventus/aggregate_root'

  class << self

    def persistence
      @persistence ||= Eventus::Persistence::InMemory.new
    end

    def persistence=(val)
      @persistence = val
    end
  end
end

%w{store stream version persistence errors}.each { |r| require "eventus/#{r}" }
