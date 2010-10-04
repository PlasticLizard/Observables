require 'test_helper'

class TestBase < Test::Unit::TestCase

  context "An instance of a class that include Observables:Base" do
    setup do
      @obs = Class.new{include Observables::Base}.new
    end

    should "have a notifier" do
      assert @obs.notifier.is_a?(ActiveSupport::Notifications::Fanout)
    end

    should "allow subscriptions with just a block" do
      assert @obs.subscribe{}.is_a?(ActiveSupport::Notifications::Fanout::Subscriber)
    end

    should "allow subscriptions with a pattern and a block" do
      assert @obs.subscribe(/whatever/){}.is_a?(ActiveSupport::Notifications::Fanout::Subscriber)
    end

    should "allow unsubscribing" do
      sub = @obs.subscribe(/hi/){}
      assert @obs.notifier.listening?("hi")
      @obs.unsubscribe(sub)
      assert_equal false, @obs.notifier.listening?("hi")
    end

    should "publish a before notification prior to executing a change" do
      vals = []
      x = 0
      @obs.subscribe(/before/){|c,a|vals << c << a << x}
      @obs.send(:changing,:a_change,:this=>:that){x+=1}
      assert_equal :before_a_change, vals[0]
      assert_equal @obs.send(:create_event_args,:a_change,:this=>:that),vals[1]
      assert_equal 0, vals[2]
      assert_equal 1, x
    end

    should "publish an after notification after executing a change" do
      vals = []
      x = 0
      @obs.subscribe(/after/){|c,a|vals << c << a << x}
      @obs.send(:changing,:a_change,:this=>:that){x+=1}
      assert_equal :after_a_change, vals[0]
      assert_equal @obs.send(:create_event_args,:a_change,:this=>:that),vals[1]
      assert_equal 1, vals[2]
      assert_equal 1, x
    end

    should "execute a proc passed in as changes to the event args" do
      vals = []
      @obs.subscribe(/after/){|_,a|vals << a.changes}
      @obs.send(:changing, :a_change, :changes=>lambda {[1,2,3]}){1==1}
      assert_equal [1,2,3], vals[0]
    end

    should "provide method level access to change args" do
      vals = []
      @obs.subscribe(/after/){|_,a|vals << a.haha}
      @obs.send(:changing, :a_change, :haha=>"hoho"){1==1}
      assert_equal "hoho", vals[0]
    end

    context "Taking ownership of an observable collection" do
      setup do
        @owner = Class.new do
          def child_changed(*args)
            @changed_args = args
          end
          def another_child_changed(*args)
            @changed_args = args
          end
          def changed_args; @changed_args; end
        end
        @parent = @owner.new
      end
      should "notify the parent via standard callback method" do
        @obs.set_observer @parent
        @obs.send(:changing, :a_change){1==1}
        assert_equal @obs, @parent.changed_args[0]
      end
      should "notify the parent via custom callback method when specified" do
        @obs.set_observer @parent, :callback_method=>:another_child_changed
        @obs.send(:changing, :a_change) {1==1}
        assert_equal @obs, @parent.changed_args[0]
      end
      should "notify the parent via a block if provided" do
        changed_args = []
        @obs.set_observer(@parent) { |obs,*_| changed_args << obs }
        @obs.send(:changing, :a_change) {1==1}
        assert_equal @obs, changed_args.pop
      end
      should "respect a subscription pattern when notifying the parent" do
        events = []
        @obs.set_observer(@parent, :pattern=>/before/){|_,evt,*_| events << evt}
        @obs.send(:changing,:a_change){1==1}
        assert_equal 1, events.length
        assert_equal :before_a_change, events.pop
      end
      should "notify the parent via argless block" do
        events = []
        @obs.set_observer(@parent, :pattern=>/before/){events << 1}
        @obs.send(:changing, :a_change){1==1}
        assert_equal 1, events.length
      end
      should "notify via block when no owner is given" do
        events = []
        my_ary = [1,2,3]
        my_ary.make_observable
        my_ary.set_observer(:pattern=>/before/){events << 1}
        my_ary << 1
        assert_equal 1, events.length
      end
      should "stop notifying the parent after clear_observer is called" do
        events = []
        @obs.set_observer(@parent){|*args|events << args}
        @obs.send(:changing,:a_change){1==1}
        assert_equal 2, events.length
        @obs.clear_observer
        @obs.send(:changing,:a_change){1==1}
        assert_equal 2, events.length
      end

    end
  end
end