require "test_helper"

class TestArrayWatcher < Test::Unit::TestCase
  context "An array which has included Observables::ArrayWatcher" do
    setup do
      @ary = Array.new([1,2,3]).tap do |a|
         class << a
           include Observables::ArrayWatcher
         end
      end
    end

    should "notify observers of any change that adds elements to itself" do
      before_methods, after_methods = [],[]
      method_list = Observables::ArrayWatcher::ADD_METHODS
      @ary.subscribe(/before_added/){|_,args|before_methods<<args[:trigger]}
      @ary.subscribe(/after_added/) {|_,args|after_methods<<args[:trigger]}
      method_list.each do |method|
        @ary.send(method,*args_for(method))
      end

      assert_equal method_list, before_methods
      assert_equal method_list, after_methods
    end

    should "notify observers of any change that modifies elements" do
      before_methods, after_methods = [],[]
      method_list = Observables::ArrayWatcher::MODIFIER_METHODS
      @ary.subscribe(/before_modified/){|_,args|before_methods<<args[:trigger]}
      @ary.subscribe(/after_modified/) {|_,args|after_methods<<args[:trigger]}
      method_list.each do |method|
        args = args_for(method)
        args ? @ary.send(method,*args) : @ary.send(method)
      end
      assert_equal method_list, before_methods
      assert_equal method_list, after_methods
    end

    should "notify observers of any change that removes elements" do
      before_methods, after_methods = [],[]
      method_list = Observables::ArrayWatcher::REMOVE_METHODS
      @ary.subscribe(/before_removed/){|_,args|before_methods<<args[:trigger]}
      @ary.subscribe(/after_removed/) {|_,args|after_methods<<args[:trigger]}
      method_list.each do |method|
        args = args_for(method)
        args ? @ary.send(method,*args) : @ary.send(method)
      end
      assert_equal method_list, before_methods
      assert_equal method_list, after_methods
    end

    context "Calling #changes on the event args" do
      should "calculate changes for #<<" do
        assert_equal [9],get_changes(@ary){ @ary << 9}[:added]
      end
      should "calculate changes for #push, #unshift" do
        [:push,:unshift].each do|method|
          ary = @ary.dup
          assert_equal [1,2,3],get_changes(ary){ary.send(method,1,2,3)}[:added]
        end
      end
      should "calculate changes for #concat" do
        assert_equal [1,2,3],get_changes(@ary){@ary.concat([1,2,3])}[:added]
      end
      should "calculate changes for insert" do
        assert_equal [3,4,5],get_changes(@ary){@ary.insert(2,3,4,5)}[:added]
      end
      should "calculate changes for delete" do
        assert_equal [2],get_changes(@ary){@ary.delete(2)}[:removed]
      end
      should "calculate changes for delete_at" do
        assert_equal [2],get_changes(@ary){@ary.delete_at(1)}[:removed]
      end
      should "calculate changes for delete_if, reject!" do
        [:delete_if, :reject!].each do |method|
          ary = @ary.dup
          assert_equal [2], get_changes(ary){ary.send(method){|i|i%2==0}}[:removed]
        end
      end
      should "calculate changes for pop" do
        assert_equal [3], get_changes(@ary){@ary.pop}[:removed]
      end
      should "calculate changes for shift" do
        assert_equal [1], get_changes(@ary){@ary.shift}[:removed]
      end
      should "calculate changes for clear" do
        assert_equal [1,2,3], get_changes(@ary){@ary.clear}[:removed]
      end
      should "calculate changes for compact!" do
        @ary = [1,2,nil,3,nil,4].tap{|a|a.make_observable}
        assert_equal [nil], get_changes(@ary){@ary.compact!}[:removed]
      end
      should "calculate changes for slice!" do
        assert_equal [2,3], get_changes(@ary){@ary.slice!(1,2)}[:removed]
      end
      should "calculate changes for uniq!" do
        @ary = [1,2,2,3,3,4,4,5].tap{|a|a.make_observable}
        assert_equal [], get_changes(@ary){@ary.uniq!}[:removed]
      end
      should "calculate changes for replace" do
        assert_equal({:removed=>@ary.dup,:added=>[4,5,6,7]}, get_changes(@ary){@ary.replace([4,5,6,7])})
      end
      should "calculate changes for []=" do
        assert_equal [6,7,8,9], get_changes(@ary){@ary[3,4]=[6,7,8,9]}[:added]
      end
      should "calculated changes for []= when []= is a modification method" do
        assert_equal({:removed=>[1],:added=>[9]},get_changes(@ary){@ary[0]=9})
      end
      should "return the original array as changes for other modification methods of array" do
        [:collect!, :map!, :flatten!, :reverse!, :sort!].each do |method|
          ary = @ary.dup
          assert_equal({:removed=>ary.dup, :added=>ary.dup.tap{|a|a.send(method)}}, get_changes(ary){ary.send(method)})
        end
      end
      should "return the original array as changes for fill" do
        assert_equal({:removed=>@ary.dup, :added=>@ary.dup.fill("*")}, get_changes(@ary){@ary.fill("*")})
      end
    end
  end

  def args_for(method)
    case method
      when :<<, :push, :unshift, :delete, :delete_at  then [1]
      when :concat, :replace then [[1,2]]
      when :fill then ["*"]
      when :insert, :"[]=", :slice! then [1,1]
      when :flatten!, :collect!, :map!, :reverse!, :sort!,
           :clear, :compact!, :pop, :reject!, :uniq!, :delete_if, :shift then nil
    end
  end

  def get_changes(ary)
    changes = []
    sub = ary.subscribe(/after/){|_,args|changes << args.changes}
    yield
    ary.unsubscribe(sub)
    changes.pop
  end
end