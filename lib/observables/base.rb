require 'active_support/concern'
require "active_support/notifications/fanout"
require 'active_support/core_ext/object/duplicable'

module Observables
  module Base
    extend ActiveSupport::Concern

    def notifier
      @notifier ||= ActiveSupport::Notifications::Fanout.new
    end

    def subscribe(pattern=nil,&block)
      notifier.subscribe(pattern,&block)
    end

    def unsubscribe(subscriber)
      notifier.unsubscribe(subscriber)
    end

    def dup
      super.tap {|s|s.make_observable}
    end

    protected

    def changing(change_type,opts)
      args = create_event_args(change_type,opts)
      notifier.publish "before_#{change_type}".to_sym, args
      yield.tap do
        notifier.publish "after_#{change_type}".to_sym, args
      end
    end

    def create_event_args(change_type,opts={})
      args = {:change_type=>change_type, :current_values=>self}.merge(opts)
      class << args
        def changes
          chgs, cur_values = self[:changes], self[:current_values]
          chgs && chgs.respond_to?(:call) ? chgs.call(cur_values) : chgs
        end

        def method_missing(method)
          self.keys.include?(method) ? self[method] : super
        end
      end
      args.delete(:current)
      args
    end

    def changes_for(change_type,trigger_method,*args,&block)
      #This method should return a lambda that takes the current
      #value of the collection as an argument, and returns
      #the expected changes that will result from trigger_method
      nil
    end

    module ClassMethods
      def override_mutators(change_groups)
        change_groups.each_pair do |change_type,methods|
          methods.each do |method|
            class_eval <<-EOS
              def #{method}(*args,&block)
                changes = changes_for(:#{change_type},:#{method},*args,&block)
                changing(:#{change_type},:trigger=>:#{method}, :changes=>changes){super}
              end
            EOS
          end
        end
      end
    end

  end
end
