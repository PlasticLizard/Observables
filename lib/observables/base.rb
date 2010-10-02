require "active_support/notifications/fanout"
require 'active_support/core_ext/object/duplicable'

module Observables
  module Base
    def notifier
      @notifier ||= ActiveSupport::Notifications::Fanout.new
    end

    def subscribe(pattern=nil,&block)
      notifier.subscribe(pattern,&block)
    end

    def unsubscribe(subscriber)
      notifier.unsubscribe(subscriber)
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

  end
end
