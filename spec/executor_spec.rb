require 'spec_helper'
require 'executor'
require 'logger'

describe Executor do
  let (:failing_cmd) { "expr 5 / 0" }
    context "exceptions" do
      it "initializes" do
        expect {
          raise Executor::CommandFailure.new("foo")
        }.to raise_exception(Executor::CommandFailure, "foo")
      end
    end
    context ".return_or_raise" do

      let(:cmd) { "echo test"}
      let(:output) { "test output" }

      let(:options) { {:raise_exceptions => true, :logger=>stub(:info=>nil)} }
      it "returns output if successful" do
        output = "test"
        Executor.return_or_raise("echo test",true, output, options).should == output
      end

      it "raises exceptions when configured" do
        expect {
          Executor.return_or_raise(cmd, false, output, options)
        }.to raise_exception(Executor::CommandFailure, /#{cmd}.*#{output}/)
      end

     it "returns an exception if async" do
        Executor.return_or_raise(cmd, false, output, options.merge(:async=>true)).should be_an(Executor::CommandFailure)
     end 
    end
    context ".command" do
      context "instance configuration" do
        it "overrides class-level config for a single command" do
          Executor.configure(:raise_exceptions => false)
          expect {
            Executor.command(failing_cmd, :raise_exceptions=>true)
          }.to raise_exception(Executor::CommandFailure)
        end
      end
      context "async" do
        before do
          Executor.configure(
            :raise_exceptions => true
          )
        end

        it "uses a separate thread" do
          i = 0
          Executor.command("sleep 3 && echo 5") do |result|
            i+=1 
          end  
          i.should == 0
          sleep 5
          i.should == 1
        end

        it "calls the block passed to it" do
          block_called = Executor.command(failing_cmd) do |result|
            true
          end || false
          block_called.should be_true
        end
        it "should raise an exception upon non zero exit" do
          Executor.command(failing_cmd) do |result|
            result.should be_kind_of Executor::CommandFailure
          end
        end
        it "with explicit async config, raise exception if no block given" do
          expect {
            Executor.command(failing_cmd, :async=>true)
          }.to raise_exception(ArgumentError)
        end
      end
      context "redirection" do
        before do
          Executor.configure(
            :redirect_stderr => true,
            :raise_exceptions => false
          )
        end
        it "redirects stderr" do
          result = Executor.command(failing_cmd)
          result.should =~ /expr: division by zero/
        end
      end
      context "non-async" do 
        before do
          Executor.configure(
            :raise_exceptions => true
          )
        end
        it "should raise an exception upon non zero exit" do
          expect {
            Executor.command(failing_cmd)
          }.to raise_exception(Executor::CommandFailure)
        end
      end
    end
    context "logging" do
      it "should log errors" do
        logger = Logger.new(StringIO.new)
        logger.should_receive(:info).with(instance_of(String)).any_number_of_times
        Executor.configure(
          :logger => logger,
          :raise_exceptions => false
        )
        Executor.command("expr 5 / 0")
      end 
    end
    context "without options" do
      it "should be able to execute 'echo x' " do
        Executor.command(%Q{echo "x"}) 
      end
      it "should be able to execute sleep && echo " do
        start = Time.now.to_i
        Executor.command("sleep 2 && echo 'test'") do |result|
          finish = Time.now.to_i
          (finish-start).should be_greater_than(2)
        end
      end
    end


    describe "on the roadmap" do
      pending "with eventmachine" do
        it "uses em::popen"
      end
      pending "timeouts" do
        it "should capture timeouts" do
          expect {
            Executor.command("sleep 5", :timeout=>2)
          }.to raise_exception(Executor::TimeoutFailure)
        end
        it "should fail for timeout on async" do
          Executor.command("sleep 5", :timeout => 2) do |result|
            raise result
          end
          sleep 5
        end
      end
    end
end
