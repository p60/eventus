require 'spec_helper'

describe Eventus::Persistence::InMemory do
  let(:options) { {:path => '%'} }
  let(:persistence) { Eventus::Persistence::InMemory.new(options) }
  let(:uuid) { UUID.new }

  it "should store complex objects" do
    id = uuid.generate :compact
    o = {'a' => 'super', 'complex' => ['object', 'with', {'nested' => ['members', 'galore', 1]}]}
    commit = create_commit(id, 1, o)
    persistence.commit(commit)

    result = persistence.load id
    result[0].should == commit[0]
  end

  it "should return no events when key not found" do
    result = persistence.load "my_id"
    result.should be_empty
  end

  it "should return events ordered" do
    id = uuid.generate :compact
    persistence.commit create_commit(id, 5, "five", "six")
    persistence.commit create_commit(id, 1, "one", "two")
    persistence.commit create_commit(id, 3, "three", "four")
    persistence.commit create_commit("other", 1, "cake", "batter")

    result = persistence.load id
    result.map{|r| r['body']}.should == ["one", "two", "three", "four", "five", "six"]
  end

  describe "when events exist" do
    let(:id) { uuid.generate :compact }
    let(:events) { create_commit(id, 1, *(1..20)).each_with_index {|e,i| e['dispatched'] = i.even? } }
    before do
      persistence.commit events
      other_events = create_commit("other", 1, *(1..60)).each_with_index {|e,i| e['dispatched'] = i.even? }
      persistence.commit other_events
    end

    it "should load events" do
      result = persistence.load id
      result.length.should == 20
    end

    it "should load undispatched events" do
      result = persistence.load_undispatched
      result.length.should == 40
    end

    it "should mark an event as dispatched" do
      result = persistence.load_undispatched[0]
      persistence.mark_dispatched(result['sid'], result['sequence'])
      persistence.load_undispatched.include?(result).should be_false
    end

    it "should throw concurrency exception if the same event number is added" do
      lambda {persistence.commit create_commit(id, 3, "This is taken")}.should raise_error(Eventus::ConcurrencyError)
    end

    it "should rollback changes on concurrency error" do
      begin
        persistence.commit create_commit(id, 3, "first", "second", "third")
      rescue Eventus::ConcurrencyError
      end

      result = persistence.load id
      result.length.should == 20
    end

    it "should load all events from a minimum" do
      result = persistence.load id, 10
      result.length.should == 11
    end
  end

  describe "when serialization is set" do
    let(:serializer) { double }
    before do
      options[:serializer] = serializer
    end

    it "should use serializer" do
      input = "original"
      ser = "i'm serialized!"
      id = uuid.generate :compact
      commit = create_commit(id, 1, input)

      serializer.should_receive(:serialize).with(commit[0]).and_return(ser)
      serializer.should_receive(:deserialize).with(ser).and_return(input)


      persistence.commit commit
      result = persistence.load id
      result[0].should == input
    end
  end
end
