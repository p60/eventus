require 'spec_helper'

describe Eventus::Persistence::KyotoCabinet do
  let(:options) { {:path => '%'} }
  let(:persistence) { Eventus::Persistence::KyotoCabinet.new(options) }
  let(:uuid) { UUID.new }

  it "should pack keys" do
    1000.times do
      key = uuid.generate(:compact)
      packed = persistence.packed(key)
      packed.unpack('H*')[0].should == key
    end
  end

  it "should store complex objects" do
    id = uuid.generate :compact
    o = {'a' => 'super', 'complex' => ['object', 'with', {'nested' => ['members', 'galore', 1]}]}
    persistence.commit id, 1, [o]

    events = persistence.load id
    events[0].should == o
  end

  describe "when events exist" do
    let(:id) { uuid.generate :compact }
    before do
      events = (1..20).map {|i| "Body #{i}"}
      persistence.commit id, 1, events
      other_events = (1..60).map {|i| "Other #{i}"}
      persistence.commit uuid.generate(:compact), 1, events
    end

    it "should load events" do
      result = persistence.load id
      result.length.should == 20
    end

    it "should throw concurrency exception if the same event number is added" do
      lambda {persistence.commit id, 3, ["This is taken"]}.should raise_error(Eventus::ConcurrencyError)
    end

    it "should rollback changes on concurrency error" do
      persistence.commit id, 3, ["first", "second", "third"] rescue nil

      result = persistence.load id
      result.length.should == 20
    end
  end

  describe "when serialization is set" do
    let(:serializer) { stub }
    before do
      options[:serialize] = lambda { |obj| serializer.serialize(obj) }
      options[:deserialize] = lambda { |obj| serializer.deserialize(obj) }
    end

    it "should use serializer" do
      input = "original"
      ser = "i'm serialized!"

      serializer.should_receive(:serialize).with(input).and_return(ser)
      serializer.should_receive(:deserialize).with(ser).and_return(input)

      id = uuid.generate :compact

      persistence.commit id, 1, [input]
      result = persistence.load id
      result[0].should == input
    end
  end
end
