module ActiveRecordLite
  module Hooks
    def after_initialize(*args, &block)
      @_after_initialize_hooks ||= []

      args.each do |hook|
        if (hook.is_a?(Symbol) || hook.is_a?(String)) && self.method_defined?(hook)
          @_after_initialize_hooks.push(hook.to_sym)
        elsif hook.respond_to?(:call)
          @_after_initialize_hooks.push(hook)
        else
          raise "Invalid after_initialize hook: '#{hook}'"
        end
      end

      @_after_initialize_hooks.push(block) if block
    end

    def after_initialize_eval(instance)
      @_after_initialize_hooks ||= []

      @_after_initialize_hooks.each do |hook|
        if hook.is_a?(Symbol)
          instance.send(symbol)
        else
          instance.instance_eval &hook
        end
      end
    end
  end
end
