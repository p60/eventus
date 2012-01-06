require 'uuid'
require 'kyotocabinet'

module Eventus
end

%w{store stream version persistence}.each { |r| require "eventus/#{r}" }
