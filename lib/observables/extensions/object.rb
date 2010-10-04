class ::Object
  def can_be_observable?
    respond_to?(:make_observable)
  end

  def observable?
    kind_of?(Observables::Base)
  end

end