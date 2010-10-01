class ::Array
  def make_observable
    class << self; include Observables::ArrayWatcher; end
  end

  def observable?
    respond_to?(:notifier)
  end

end