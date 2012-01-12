require 'spec_helper'

describe Eventus::Stream do
  let(:id) { UUID.generate(:compact) }
  let(:stream) { Eventus::Stream.new(id, persistence, dispatcher) }
  let(:persistence) { stub(:persistence).as_null_object }
  let(:dispatcher) { stub(:dispatcher).as_null_object }

  it "should use id" do
    stream.id.should == id
  end

  it "should have no committed events" do
    stream.committed_events.should be_empty
  end

  it "should have no uncommitted events" do
    stream.uncommitted_events.should be_empty
  end

  describe "when events available from persistence" do
    before do
      persistence.should_receive(:load).and_return([stub, stub])
    end

    it "should have an equal number of events" do
      stream.version.should == 2
    end

    it "should have no uncommitted events" do
      stream.uncommitted_events.should be_empty
    end
  end

  describe "when events added" do
    before do
      stream << stub
      stream.add stub
    end

    it "should have uncommitted events" do
      stream.uncommitted_events.length.should == 2
    end

    describe "when committed" do
      before do
        persistence.should_receive(:commit)
        dispatcher.should_receive(:dispatch)
        stream.commit
      end

      it "should have committed events" do
        stream.version.should == 2
      end

      it "should have no uncommitted events" do
        stream.uncommitted_events.should be_empty
      end
    end
  end

  describe "when a concurrency error occurs" do
    before do
      persistence.should_receive(:commit).and_raise(Eventus::ConcurrencyError)
      stream << stub(:event)
    end

    it "should reraise concurrency error" do
      lambda {stream.commit}.should raise_error(Eventus::ConcurrencyError)
    end

    it "should load latest events" do
      persistence.should_receive(:load).with(id, 1).and_return([stub, stub, stub])
      stream.commit rescue nil
      stream.version.should == 3
    end
  end
end
