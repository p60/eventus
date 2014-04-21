require 'spec_helper'

describe Eventus::Dispatchers::Synchronous do
  let(:persistence){ double.as_null_object }
  let(:dispatcher) { Eventus::Dispatchers::Synchronous.new(persistence) { @hit = true } }

  before do
    persistence.should_receive(:mark_dispatched)
    dispatcher.dispatch([double])
  end

  it "should invoke block" do
    @hit.should == true
  end
end
