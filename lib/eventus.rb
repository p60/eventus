require 'uuid'

module Eventus
  autoload :Serializers, 'eventus/serializers'
end

%w{store stream version persistence errors}.each { |r| require "eventus/#{r}" }
