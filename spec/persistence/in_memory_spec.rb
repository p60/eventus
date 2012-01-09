require 'spec_helper'

describe Eventus::Persistence::InMemory do
  let(:options) { {:path => '%'} }
  let(:persistence) { Eventus::Persistence::InMemory.new(options) }
  let(:uuid) { UUID.new }

  it "should store complex objects" do
    id = uuid.generate :compact
    o = {'a' => 'super', 'complex' => ['object', 'with', {'nested' => ['members', 'galore', 1]}]}
    persistence.commit id, 1, [o]

    result = persistence.load id
    result[0].should == o
  end

  it "should return no events when key not found" do
    result = persistence.load "my_id"
    result.should be_empty
  end

  it "should return events ordered" do
    id = uuid.generate :compact
    persistence.commit id, 5, ["five", "six"]
    persistence.commit id, 1, ["one", "two"]
    persistence.commit id, 3, ["three", "four"]
    persistence.commit "other", 1, ["cake", "batter"]

    result = persistence.load id
    result.should == ["one", "two", "three", "four", "five", "six"]
  end

  describe "when events exist" do
    let(:id) { uuid.generate :compact }
    let(:events) { (1..20).map {|i| "Body #{i}"} }
    before do
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

    it "should load all events from a minimum" do
      result = persistence.load id, 10
      result.length.should == 11
    end
  end

  describe "when serialization is set" do
    let(:serializer) { stub }
    before do
      options[:serializer] = serializer
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
