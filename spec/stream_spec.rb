require 'spec_helper'

describe Eventus::Stream do
  let(:id) { UUID.generate(:compact) }
  let(:stream) { Eventus::Stream.new(id, persistence, dispatcher) }
  let(:persistence) { double(:persistence).as_null_object }
  let(:dispatcher) { double(:dispatcher).as_null_object }

  it "should use id" do
    stream.id.should == id
  end

  it "should have no committed events" do
    stream.committed_events.should be_empty
  end

  it "should have no uncommitted events" do
    stream.uncommitted_events.should be_empty
  end

  it "should not commit to persistence if no uncommited events" do
    persistence.should_not_receive(:commit)
    stream.uncommitted_events.clear
    stream.commit
  end

  describe "when events available from persistence" do
    before do
      persistence.should_receive(:load).and_return([double, double])
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
      stream.add "french"
      stream.add "bread"
    end

    it "should have uncommitted events" do
      stream.uncommitted_events.length.should == 2
    end

    describe "when committed" do
      before do
        payload = {:truck => 'money'}
        persistence.should_receive(:commit).and_return(payload)
        dispatcher.should_receive(:dispatch).with(payload)
        stream.commit
      end

      it "should have timestamp on committed events" do
        stream.committed_events.all?{ |e| e['time'] }.should == true
      end

      it "should have stream id on committed events" do
        stream.committed_events.all?{ |e| e['sid'] }.should == true
      end

      it "should have sequence id on committed events" do
        stream.committed_events.all?{ |e| e['sequence'] }.should == true
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
      stream.add "butter"
    end

    it "should reraise concurrency error" do
      lambda {stream.commit}.should raise_error(Eventus::ConcurrencyError)
    end

    it "should load latest events" do
      persistence.should_receive(:load).with(id, 0).and_return([double, double, double])
      stream.commit rescue nil
      stream.version.should == 3
    end
  end
end
