require 'spec_helper'

class TestAgg
  include Eventus::AggregateRoot

  attr_accessor :loaded

  conflicts :lemon_squeezed => :cake_baked

  def bake_cake
    apply_change :cake_baked, :flavor => 'strawberry'
  end

  apply :dino do |e|
    @loaded = true
  end
end

describe Eventus::AggregateRoot do
  let(:events) { [] }
  let(:persistence) { double.as_null_object }

  before do
    TestAgg.stub(:persistence).and_return(persistence)
  end

  it "should load a new aggregate from find" do
    result = TestAgg.find('abc')
    result.should_not be_nil
  end

  describe "when events exist" do
    before do
      persistence.should_receive(:load).with('abc').and_return(events)
      events << {'name' => 'dino', 'body' => {}}
    end

    it "should apply the event" do
      result = TestAgg.find('abc')
      result.loaded.should == true
    end
  end

  describe "when applying a new change" do
    let(:aggregate) { TestAgg.new }
    let(:stream) { double(:stream, :committed_events => []) }

    before do
      aggregate.populate(stream)
    end

    it "should be added to the stream" do
      stream.should_receive(:add)
      aggregate.bake_cake
    end
  end

  describe "when saving" do
    let(:aggregate) { TestAgg.new }
    let(:stream) { double(:stream, :committed_events => events, :version => 0) }
    let(:events) { [{'name' => :lemon_squeezed}] }

    before do
      aggregate.populate(stream)
    end

    it "should return true when no concurrency error" do
      stream.should_receive(:commit)
      aggregate.save.should == true
    end

    it "should return false if no conflict" do
      stream.should_receive(:commit).and_raise(Eventus::ConcurrencyError)
      stream.should_receive(:uncommitted_events).and_return([{'name' => 'coconut'}])

      aggregate.save.should == false
    end

    it "should raise conflict error if conflict exists" do
      stream.should_receive(:commit).and_raise(Eventus::ConcurrencyError)
      stream.should_receive(:uncommitted_events).and_return([{'name' => 'cake_baked'}])
      lambda {aggregate.save}.should raise_error(Eventus::ConflictError)
    end

    it "should invoke on_concurrency_error when concurrency error" do
      stream.should_receive(:commit).and_raise(Eventus::ConcurrencyError)
      aggregate.should_receive(:on_concurrency_error).with(0, an_instance_of(Eventus::ConcurrencyError))
      aggregate.save
    end
  end
end
