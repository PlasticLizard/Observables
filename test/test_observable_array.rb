require "test_helper"

class TestObservablesArray < Test::Unit::TestCase
  context "An Observables::Array" do
    should "be observable" do
      assert Observables::Array.new.observable?
    end
    should "be an array" do
      assert Observables::Array.new.kind_of?(::Array)
    end

  end
end