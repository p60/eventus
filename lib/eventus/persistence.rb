module Eventus
  module Persistence
    autoload :KyotoCabinet, 'eventus/persistence/kyotocabinet'
    autoload :Mongo, 'eventus/persistence/mongo'
    autoload :Redis, 'eventus/persistence/redis'
    autoload :InMemory, 'eventus/persistence/in_memory'
    autoload :Sequel, 'eventus/persistence/sequel'
  end
end
