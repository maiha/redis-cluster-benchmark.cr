require "./spec_helper"

include Bench::Commands

private def default_context
  Context.new(keyspace: (UInt32::MAX / 2).to_i32)
end

private def parse1(str, ctx : Context = default_context)
  cmds = Bench::Commands.parse(str, ctx)
  cmds.size.should eq(1)
  return cmds.first
end

describe Bench::Commands do
  describe ".parse" do
    it "get x" do
      cmd = parse1("get x")
      10.times do
        cmd.feed.should eq(["get", "x"])
      end
    end

    it "get x__rand_int__" do
      cmd = parse1("get x__rand_int__")
      args = cmd.feed
      args.size.should eq(2)
      args[0].should eq("get")
      (args[1] =~ /^x\d+$/).should be_a(Int32)
    end

    it "set __rand_int__ __rand_int__" do
      cmd = parse1("set __rand_int__ __rand_int__")
      args = cmd.feed
      args.size.should eq(3)
      args[0].should eq("set")
      (args[1] =~ /^\d+$/).should be_a(Int32)
      (args[2] =~ /^\d+$/).should be_a(Int32)
    end

    it "get __rand_int__ (with keyspace=1)" do
      cmd = parse1("get __rand_int__",  Context.new(keyspace: 1))
      10.times do
        cmd.feed.should eq(["get", "0"])
      end
    end

    it "get __foo__ (with custom mapping)" do
      custom = {"__foo__" => "XYZ" }
      cmd = parse1("get __foo__",  Context.new(custom))
      cmd.feed.should eq(["get", "XYZ"])
    end
  end
end
