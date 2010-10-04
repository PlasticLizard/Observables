class ::Array
  def make_observable
    class << self; include Observables::ArrayWatcher; end unless observable?
  end
end