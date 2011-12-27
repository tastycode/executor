require "executor/version"
require "nullobject"
require "timeout"

module Executor

  ExecutorFailure = Class.new(StandardError)
  CommandFailure = Class.new(ExecutorFailure) 
  TimeoutFailure = Class.new(ExecutorFailure)

  class << self
    def method_missing(meth, *args, &block)
      if Executor.respond_to?(meth, true)
        Executor.send(meth, *args, &block)
      else
        super
      end
    end
  end

  class Executor
    DEFAULTS = {
      :redirect_stderr => false,
      :raise_exceptions => true,
      :async => false,
      :logger => Null::Object.instance
    }
    class << self
      attr_reader :config

      def configure(config={})
        @config||=Executor::DEFAULTS.merge(config)
      end 

      def command(cmd, options={}, &block)
        options = configure.dup.merge(options)
        options[:logger].info "COMMAND: #{cmd}"
        options[:async] ||= block_given?

        raise ArgumentError.new("No block given for async command") if (options[:async] && !block_given?)

        if options[:async]
          handle_async(cmd, options, &block)
        else
          return handle_nonasync(cmd, options)
        end
      end

      private

      def handle_nonasync(cmd, options)
          stmt = ["(#{cmd})"]
          stmt << "2>&1" if @config[:redirect_stderr]
          if options[:timeout]
            Timeout::timeout(options[:timeout]) do
              output = %x{#{stmt*" "}}
            end
          else
            output = %x{#{stmt*" "}}
          end
          options[:logger].info "Non-async output for #{cmd}: #{output.inspect}"
          return return_or_raise(cmd, $?.success?, output, options)
      rescue Timeout::Error=>e
        raise TimeoutFailure.new(e)
      end

      def handle_async(cmd, options, &block)
          Thread.new do 
            IO.popen(cmd) do |pipe|
              output = pipe.read
              options[:logger].info "Async output for #{cmd}: #{output.inspect}"
              pipe.close
              yield return_or_raise(cmd, $?.success?, output, options) rescue $!
            end
          end
      end

      def return_or_raise(cmd, success, output, options = nil)
        options ||= @config || configure
        options[:logger].info "RETURN(#{cmd}): #{output}"
        exception =  CommandFailure.new(%Q{Command "#{cmd}" failed with #{output}}) 
        return output if success
        return exception if options[:async]
        raise exception if options[:raise_exceptions]
        return output
      end
    end
  end
end
