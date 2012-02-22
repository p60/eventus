module Eventus
  module Persistence
    autoload :KyotoCabinet, 'eventus/persistence/kyotocabinet'
    autoload :Mongo, 'eventus/persistence/mongo'
    autoload :InMemory, 'eventus/persistence/in_memory'
  end
end
