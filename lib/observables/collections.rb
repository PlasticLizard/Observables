module Observables
  class Array < ::Array
    include ArrayWatcher
    def initialize(*args)
      super(*args)
    end
  end
end