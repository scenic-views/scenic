require 'spec_helper'

module Scenic
  describe Scenic::Statements do

    subject { Class.new { extend Statements } }

    it { is_expected.to respond_to(:create_view) }
    it { is_expected.to respond_to(:drop_view) }
    it { is_expected.to respond_to(:update_view) }
    it { is_expected.to respond_to(:replace_view) }
    it { is_expected.to respond_to(:replace_view) }

    it { is_expected.to respond_to(:create_function) }
    it { is_expected.to respond_to(:drop_function) }
    it { is_expected.to respond_to(:update_function) }

  end
end
