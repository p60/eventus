module Eventus
  class ConcurrencyError < ::StandardError; end
  class ConflictError < ::StandardError; end
  class ConnectionError  < ::StandardError; end
end
