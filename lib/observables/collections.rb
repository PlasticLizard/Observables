module Observables
  class Array < ::Array
    include ArrayWatcher
    def initialize(*args)
      super(*args)
    end
  end

  class Hash < ::Hash
    include HashWatcher
    def initialize(*args)
      super(*args)
    end
  end
end