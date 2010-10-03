class ::Hash
  def make_observable
    class << self; include Observables::HashWatcher; end
  end

  def observable?
    respond_to?(:subscribe)
  end

end