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
      method_list = [:<<, :push, :concat, :fill, :insert, :unshift]
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
      method_list = [:"[]=", :collect!, :map!, :flatten!, :replace, :reverse!, :sort!]
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
      method_list = [:clear, :compact!, :delete, :delete_at, :delete_if, :pop, :reject!, :shift, :slice!, :uniq!]
      @ary.subscribe(/before_removed/){|_,args|before_methods<<args[:trigger]}
      @ary.subscribe(/after_removed/) {|_,args|after_methods<<args[:trigger]}
      method_list.each do |method|
        args = args_for(method)
        args ? @ary.send(method,*args) : @ary.send(method)
      end
      assert_equal method_list, before_methods
      assert_equal method_list, after_methods
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
end