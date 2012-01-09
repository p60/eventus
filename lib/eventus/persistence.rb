module Eventus
  module Persistence
    autoload :KyotoCabinet, 'eventus/persistence/kyotocabinet'
    autoload :InMemory, 'eventus/persistence/in_memory'
  end
end
