require 'spec_helper'

class TestConsumer
  include Eventus::Consumer

  attr_accessor :loaded

  def bake_cake
    apply_change :cake_baked, :flavor => 'strawberry'
  end

  apply :dino do |e|
    @loaded = true
  end
end

describe Eventus::Consumer do
  it "should populate from events" do
    events = [
      {'name' => 'dino', 'body' => {}}
    ]
    cons = TestConsumer.new
    cons.populate events
    cons.loaded.should == true
  end

  it "should ignore events it's unconcerned with" do
    cons = TestConsumer.new
    cons.bake_cake
  end
end
