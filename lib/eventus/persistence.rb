module Eventus::Persistence
end

%w{kyotocabinet}.each { |lib| require "eventus/persistence/#{lib}" }
