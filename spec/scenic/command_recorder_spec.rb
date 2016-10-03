require 'spec_helper'

module Scenic
  describe Scenic::CommandRecorder do

    subject { Class.new { extend CommandRecorder } }

    it { is_expected.to respond_to(:create_view) }
    it { is_expected.to respond_to(:drop_view) }
    it { is_expected.to respond_to(:update_view) }
    it { is_expected.to respond_to(:replace_view) }
    it { is_expected.to respond_to(:invert_create_view) }
    it { is_expected.to respond_to(:invert_drop_view) }
    it { is_expected.to respond_to(:invert_update_view) }
    it { is_expected.to respond_to(:invert_replace_view) }


    it { is_expected.to respond_to(:create_function) }
    it { is_expected.to respond_to(:drop_function) }
    it { is_expected.to respond_to(:update_function) }
    it { is_expected.to respond_to(:invert_create_function) }
    it { is_expected.to respond_to(:invert_drop_function) }
    it { is_expected.to respond_to(:invert_update_function) }
    
  end
end
