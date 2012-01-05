require 'spec_helper'

describe Eventus::Store do
  let(:persistence) { stub(:persistence).as_null_object }
  let(:store) { Eventus::Store.new(persistence) }
  let(:uuid) { UUID.new }
  let(:stream) { stub(:stream) }

  describe "when opening an event stream" do
    let(:id) { uuid.generate(:compact) }
    let(:result) { store.open id }

    it "should request from persistence" do
      persistence.should_receive(:get_events)
      result
    end

    it "should return a stream" do
      result.should_not be_nil
    end
  end
end
