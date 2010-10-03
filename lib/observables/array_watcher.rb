
module Observables
  module ArrayWatcher
    include Observables::Base

    ADD_METHODS =       :<<, :push, :concat, :insert, :unshift
    MODIFIER_METHODS =  :collect!, :map!, :flatten!, :replace, :reverse!, :sort!, :fill
    REMOVE_METHODS =    :clear, :compact!, :delete, :delete_at, :delete_if, :pop, :reject!, :shift, :slice!, :uniq!

    #[]= can either be an add method or a modifier method depending on
    #if the previous key exists
    def []=(*args)
      change_type = args[0] >= length ? :added : :modified
      changes = changes_for(change_type,:"[]=",*args)
      changing(change_type,:trigger=>:"[]=", :changes=>changes) {super}
    end

    override_mutators :added=>    ADD_METHODS,
                      :modified=> MODIFIER_METHODS,
                      :removed=>  REMOVE_METHODS

    def changes_for(change_type, trigger_method, *args, &block)
      prev = self.dup.to_a
      if change_type == :added
        case trigger_method
          when :"[]=" then lambda {args[-1]}
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
          when :replace then lambda {{:removed=>prev, :added=>args[0]}}
          when :"[]=" then lambda {{:removed=>[prev[*args[0..-2]]].flatten, :added=>[args[-1]].flatten}}
          else lambda {|cur|{:removed=>prev.uniq, :added=>cur}}
        end
      end
    end
  end
end
