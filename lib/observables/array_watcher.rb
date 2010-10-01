
module Observables
  module ArrayWatcher
    include Observables::Base

    [:<<, :push, :concat, :fill, :insert, :unshift].each do |add_method|
      class_eval <<-EOS
        def #{add_method}(*args)
          changing(:added,:trigger=>:#{add_method}) { super }
        end
      EOS
    end

    [:"[]=", :collect!, :map!, :flatten!, :replace, :reverse!, :sort!].each do |mod_method|
      class_eval <<-EOS
        def #{mod_method}(*args)
          changing(:modified,:trigger=>:#{mod_method}) { super }
        end
      EOS
    end

    [:clear, :compact!, :delete, :delete_at, :delete_if, :pop, :reject!, :shift, :slice!, :uniq!].each do |del_method|
      class_eval <<-EOS
        def #{del_method}(*args)
          changing(:removed,:trigger=>:#{del_method}) { super }
        end
      EOS
    end

  end
end
