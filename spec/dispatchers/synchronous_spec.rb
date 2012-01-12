require 'spec_helper'

describe Eventus::Dispatchers::Synchronous do
  let(:persistence){ stub.as_null_object }
  let(:dispatcher) { Eventus::Dispatchers::Synchronous.new(persistence) { @hit = true } }

  before do
    persistence.should_receive(:mark_dispatched)
    dispatcher.dispatch([stub])
  end

  it "should invoke block" do
    @hit.should == true
  end
end
