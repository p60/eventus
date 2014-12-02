require 'spec_helper'

describe Eventus::Persistence::Sequel do
  let(:persistence) { Eventus::Persistence::Sequel.new(@db) }
  let(:uuid) { UUID.new }

  before(:all) { @db = Sequel::DATABASES.first }

  it "should store complex objects" do
    id = uuid.generate :compact
    o = {'a' => 'super', 'complex' => ['object', 'with', {'nested' => ['members', 'galore', 1]}]}
    commit = create_commit(id, 1, o)
    persistence.commit(commit)
    event = commit[0]

    result = persistence.load(id)[0]
    result['name'].should == event['name']
    result['sid'].should == event['sid']
    result['time'].should == Time.parse(event['time'])
    result['sequence'].should == event['sequence']
    result['dispatched'].should be_false
    result['body'].should == event['body']
  end

  it "should return events" do
    id = uuid.generate :compact
    o = {'a' => 'super', 'complex' => ['object', 'with', {'nested' => ['members', 'galore', 1]}]}
    commit = create_commit(id, 1, o)
    events = persistence.commit(commit)
    events.should == commit
  end

  it "should return no events when key not found" do
    result = persistence.load "my_id"
    result.should be_empty
  end

  it "should return events ordered" do
    id = uuid.generate :compact
    persistence.commit create_commit(id, 1, {"foo" => "one"}, {"foo" => "two"})
    persistence.commit create_commit(id, 3, {"foo" => "three"}, {"foo" => "four"})
    persistence.commit create_commit(id, 5, {"foo" => "five"}, {"foo" => "six"})
    persistence.commit create_commit("other", 1, {"foo" => "cake"}, {"foo" => "batter"})

    result = persistence.load id
    result.map{|r| r['body']['foo']}.should == ["one", "two", "three", "four", "five", "six"]
  end

  describe "when events exist" do
    let(:id) { uuid.generate :compact }
    let(:events) { create_commit(id, 1, *(1..20).map{|i| {'foo' => i}}).each_with_index{ |e,i| e['dispatched'] = i.even? } }
    before do
      other_id = uuid.generate :compact
      persistence.commit events
      other_events = create_commit(other_id, 1, *(1..60).map{|i| {'foo' => i}}).each_with_index {|e,i| e['dispatched'] = i.even? }
      persistence.commit other_events
    end

    it "should load events" do
      result = persistence.load id
      result.length.should == 20
    end

    it "should load undispatched events" do
      result = persistence.load_undispatched
      result.select{|r| r['sid'] == id}.length.should == 10
    end

    it "should mark an event as dispatched" do
      result = persistence.load_undispatched[0]
      persistence.mark_dispatched(result['sid'], result['sequence'])
      persistence.load_undispatched.include?(result).should be_false
    end

    it "should throw concurrency exception if the same event number is added" do
      expect {persistence.commit create_commit(id, 3, {"foo" => "This is taken"})}.to raise_error(Eventus::ConcurrencyError)
    end

    it "should rollback changes on concurrency error" do
      begin
        persistence.commit create_commit(id, 3, {"foo" => "first"}, {"foo" => "second"}, {"foo" => "third"})
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
end
