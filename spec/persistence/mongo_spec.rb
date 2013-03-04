require 'spec_helper'

describe Eventus::Persistence::Mongo do
  let(:persistence) { @persistence }
  let(:uuid) { UUID.new }

  before(:all) do
    @persistence = Eventus::Persistence::Mongo.new(MONGO_URI)
    @persistence.db.collection('eventus_commits').drop
  end

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
    persistence.commit create_commit(id, 1, "one", "two")
    persistence.commit create_commit(id, 3, "three", "four")
    persistence.commit create_commit(id, 5, "five", "six")
    persistence.commit create_commit(uuid.generate, 1, "cake", "batter")

    result = persistence.load id
    result.map{|r| r['body']}.should == ["one", "two", "three", "four", "five", "six"]
  end

  describe "when events exist" do
    let(:id) { uuid.generate :compact }
    let(:events) { create_commit(id, 1, *(1..5)) }
    before do
      persistence.commit events
      other_events = create_commit(uuid.generate(:compact), 1, (1..10))
      persistence.commit other_events
    end

    it "should load events" do
      result = persistence.load id
      result.length.should == events.length
    end

    it "should load undispatched events" do
      result = persistence.load_undispatched_commits
    end

    it "should mark an event as dispatched" do
      result = persistence.load_undispatched_commits[0]
      persistence.mark_commit_dispatched(result['_id'])
      persistence.load_undispatched_commits.include?(result).should be_false
    end

    it "should throw concurrency exception if the same event number is added" do
      lambda {persistence.commit create_commit(id, 1, "This is taken")}.should raise_error(Eventus::ConcurrencyError)
      lambda {persistence.commit create_commit(id, 2, "This is taken")}.should raise_error(Eventus::ConcurrencyError)
    end

    it "should rollback changes on concurrency error" do
      lambda {persistence.commit create_commit(id, 1, "first", "second", "third")}.should raise_error(Eventus::ConcurrencyError)

      result = persistence.load id
      result.should == events
    end

    it "should load all events from a minimum" do
      result = persistence.load id, 3
      result.should == events.select {|e| e['sequence'] >= 3}
    end
  end

  it 'should return nil if there are no events' do
    persistence.commit([]).should be_nil
  end

  it 'should reraise non-"already exists" errors' do
    e = Mongo::OperationFailure.new('fail', 500)
    commits = persistence.instance_eval { @commits }
    commits.stub(:insert) { raise e }
    lambda {persistence.commit create_commit('commitid', 1, "first", "second", "third")}.should raise_error(e)
  end
end

