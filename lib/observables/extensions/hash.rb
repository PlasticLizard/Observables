class ::Hash
  def make_observable
    class << self; include Observables::HashWatcher; end unless observable?
  end
end