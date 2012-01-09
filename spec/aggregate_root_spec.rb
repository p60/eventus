require 'spec_helper'

class TestAgg
  include Eventus::AggregateRoot

  attr_accessor :loaded

  def bake_cake
    apply_change :cake_baked, :flavor => 'strawberry'
  end

  apply :dino do |e|
    @loaded = true
  end
end

describe Eventus::AggregateRoot do
  let(:events) { [] }
  let(:persistence) { stub.as_null_object }

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
      events << {:name => 'dino', :body => {}}
    end

    it "should apply the event" do
      result = TestAgg.find('abc')
      result.loaded.should == true
    end
  end

  describe "when applying a new change" do
    let(:aggregate) { TestAgg.new }
    let(:stream) { stub(:stream, :committed_events => []) }

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
    let(:stream) { stub(:stream, :committed_events => []) }

    before do
      aggregate.populate(stream)
    end

    it "should commit stream" do
      stream.should_receive(:commit)
      aggregate.save
    end
  end
end
