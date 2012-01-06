require 'spec_helper'

describe Eventus::Stream do
  let(:id) { UUID.generate(:compact) }
  let(:stream) { Eventus::Stream.new(id, events) }
  let(:events) { [] }

  it "should use id" do
    stream.id.should == id
  end

  it "should have no committed events" do
    stream.committed_events.should be_empty
  end

  it "should have no uncommitted events" do
    stream.uncommitted_events.should be_empty
  end

  describe "when loaded with events" do
    let(:events) { [stub, stub] }

    it "should have an equal number of events" do
      stream.committed_events.length.should == events.length
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
        stream.commit
      end

      it "should have committed events" do
        stream.committed_events.length.should == 2
      end

      it "should have no uncommitted events" do
        stream.uncommitted_events.should be_empty
      end
    end
  end
end
