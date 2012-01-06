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
  end
end
