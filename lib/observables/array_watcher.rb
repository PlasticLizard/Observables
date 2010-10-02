
module Observables
  module ArrayWatcher
    include Observables::Base

    [:<<, :push, :concat, :insert, :unshift].each do |add_method|
      class_eval <<-EOS
        def #{add_method}(*args,&block)
          changes = changes_for(:added,:#{add_method},*args,&block)
          changing(:added,:trigger=>:#{add_method}, :changes=>changes) { super }
        end
      EOS
    end

    [:"[]=", :collect!, :map!, :flatten!, :replace, :reverse!, :sort!, :fill].each do |mod_method|
      class_eval <<-EOS
        def #{mod_method}(*args,&block)
          changes = changes_for(:modified,:#{mod_method},*args,&block)
          changing(:modified,:trigger=>:#{mod_method}, :changes=>changes) { super }
        end
      EOS
    end

    [:clear, :compact!, :delete, :delete_at, :delete_if, :pop, :reject!, :shift, :slice!, :uniq!].each do |del_method|
      class_eval <<-EOS
        def #{del_method}(*args,&block)
          changes = changes_for(:removed,:#{del_method},*args,&block)
          changing(:removed,:trigger=>:#{del_method}, :changes=>changes) { super }
        end
      EOS
    end

    def dup
      super.tap {|a|a.make_observable}
    end

    def changes_for(change_type, trigger_method, *args, &block)
      #This method returns a lambda because many uses of this library may not care
      #what the actual changes were. For those cases, it is wasteful to calculate
      #the changes particularly for very large arrays, so this lambda will only
      #get called when the consumer calls .changes on the event args
      prev = self.dup.to_a
      if change_type == :added
        case trigger_method
          when :<<, :push, :unshift then lambda {args}
          when :concat then lambda {args[0]}
          when :insert then lambda {args[1..-1]}
          else lambda { |cur| (cur - prev).uniq }
        end
      elsif change_type == :removed
        case trigger_method
          when :delete then lambda {args}
          when :delete_at then lambda {[prev[args[0]]]}
          when :delete_if, :reject! then lambda {prev.select(&block)}
          when :pop then lambda {[prev[-1]]}
          when :shift then lambda {[prev[0]]}
          else lambda { |cur| (prev - cur).uniq }
        end
      else
        case trigger_method
          when :replace then lambda {args[0]}
          when :"[]=" then args[-1]
          else lambda {prev.uniq}
        end
      end
    end
  end
end
