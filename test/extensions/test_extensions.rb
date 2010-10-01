require "test_helper"

class TestExtensions < Test::Unit::TestCase
  context "Array" do
    context "#make_observable" do

      should "detect an observable array" do
        x, y = [], [].tap{|a|a.make_observable}
        assert_equal false, x.observable?
        assert y.observable?
      end

      should "make an instance of an array observable" do
        x = []
        assert_equal false, x.observable?
        x.make_observable
        assert x.observable?
      end
    end
  end
end