require 'active_support/concern'
require "active_support/notifications/fanout"
require 'active_support/core_ext/object/duplicable'
require 'active_support/core_ext/array/extract_options'

module Observables
  module Base
    extend ActiveSupport::Concern

    module InstanceMethods
      def notifier
        @notifier ||= ActiveSupport::Notifications::Fanout.new
      end

      def subscribe(pattern=nil,&block)
        callback = block || self
        notifier.subscribe(pattern,callback)
      end

      def unsubscribe(subscriber)
        notifier.unsubscribe(subscriber)
      end

      def dup
        #This check is necessary in case a proxy is made observable,
        #with an impementation of dup that returns its non-observable
        #target
        super.tap {|s| s.make_observable if s.respond_to?(:make_observable) }
      end

      def set_observer(*args,&block)
        clear_observer
        opts = args.extract_options!
        @_observer_owner = args.pop
        @_observer_owner_callback_method = opts[:callback_method] || :child_changed
        @_observer_owner_block = block

        pattern = opts[:pattern] || /.*/
        #callback_method = opts[:callback_method] || :child_changed
        @_owner_subscription = subscribe(pattern)
      end

      def call(*args)
        block = @_observer_owner_block
        callback_method = @_observer_owner_callback_method

        block ? block.call(self,*args) :
          (@_observer_owner.send(callback_method,self,*args) if @_observer_owner && @_observer_owner.respond_to?(callback_method))
      end

      def clear_observer
        unsubscribe(@_owner_subscription) if @_owner_subscription
        @_owner_subscription = nil
      end

      protected

      def changing(change_type,opts={})
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
