require "test_helper"

class TestHashWatcher < Test::Unit::TestCase
  context "A hash which has included Observables::HashWatcher" do
    setup do
      @hash = {:a=>1,:b=>2,:c=>"3"}.tap do |h|
         class << h
           include Observables::HashWatcher
         end
      end
    end

    should "notify observers of any change that modifies elements" do
      before_methods, after_methods = [],[]
      method_list = Observables::HashWatcher::MODIFIER_METHODS
      @hash.subscribe(/before_modified/){|_,args|before_methods<<args[:trigger]}
      @hash.subscribe(/after_modified/) {|_,args|after_methods<<args[:trigger]}
      method_list.each do |method|
        args = args_for(method)
        args ? @hash.send(method,args) : @hash.send(method)
      end
      assert_equal method_list, before_methods
      assert_equal method_list, after_methods
    end

    should "notify observers of any change that removes elements" do
      before_methods, after_methods = [],[]
      method_list = Observables::HashWatcher::REMOVE_METHODS
      @hash.subscribe(/before_removed/){|_,args|before_methods<<args[:trigger]}
      @hash.subscribe(/after_removed/) {|_,args|after_methods<<args[:trigger]}
      method_list.each do |method|
        args = args_for(method)
        args ? @hash.send(method,*args) : @hash.send(method)
      end
      assert_equal method_list, before_methods
      assert_equal method_list, after_methods
    end

    context "Calling #changes on the event args" do
      should "calculate changes for #[]= as an addition" do
        assert_equal [[:f,9]],get_changes(@hash){ @hash[:f] = 9}[:added]
      end
      should "calculate changes for #[]= as a modification" do
        assert_equal({:removed=>[[:a,1]],:added=>[[:a,9]]}, get_changes(@hash){@hash[:a]=9})
      end
      should "calculate changes for #replace" do
        assert_equal({:removed=>@hash.dup.to_a,:added=>{:t=>9,:u=>10}.to_a},get_changes(@hash){@hash.replace(:t=>9,:u=>10)})
      end
      should "calculate changes for #merge!, #update" do
        [:merge!, :update].each do |method|
          hash = @hash.dup
          assert_equal({:removed=>{:c=>"3"}.to_a, :added=>{:c=>"4",:d=>5}.to_a},get_changes(hash){hash.send(method,{:c=>"4",:d=>5})})
        end
      end
      should "calculate changes for #clear" do
        assert_equal @hash.to_a, get_changes(@hash){@hash.clear}[:removed]
      end
      should "calculate changes for #delete" do
        assert_equal({:a=>1}.to_a, get_changes(@hash){@hash.delete(:a)}[:removed])
      end
      should "calculate changes for #delete_if, #reject!" do
        [:delete_if,:reject!].each do |method|
          hash = @hash.dup
          assert_equal({:a=>1,:c=>"3"}.to_a,get_changes(hash){hash.send(method){|k,v|[:a,:c].include?(k)}}[:removed])
        end
      end
      should "calculate changes for #shift" do
        assert_equal(@hash.dup.shift,get_changes(@hash){@hash.shift}[:removed])
      end
    end
  end

  def args_for(method)
    case method
      when :replace, :merge!, :update then {:e=>5}
      when :delete then :a
      else nil
    end
  end

  def get_changes(hash)
    changes = []
    sub = hash.subscribe(/after/){|_,args|changes << args.changes}
    yield
    hash.unsubscribe(sub)
    changes.pop
  end
end