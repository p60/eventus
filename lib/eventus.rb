require 'uuid'

module Eventus
  autoload :Serializers, 'eventus/serializers'
  autoload :AggregateRoot, 'eventus/aggregate_root'
end

%w{store stream version persistence errors}.each { |r| require "eventus/#{r}" }
