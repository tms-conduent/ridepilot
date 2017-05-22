require 'rails_helper'

RSpec.describe RepeatingRun, type: :model do
  it_behaves_like "a recurring ride coordinator scheduler"
    
  describe "#instantiate!" do
    # TODO Add some robust examples
    # Partially exercised by recurring_ride_coordinator_shared_examples.rb
    it "generates runs"
  end

  it_behaves_like "a recurring ride coordinator" do
    before do
      @scheduled_instance_class = Run 
      
      # To help us know what attribute to check occurrence dates against
      @occurrence_date_attribute = :date
      @scheduler_date_attribute = :start_date
    end
  end
  
  describe 'validations' do
    
    # Set some context...
    let(:provider_a) { create(:provider) }
    let(:provider_b) { create(:provider) }
    before(:each) { create(:run, :tomorrow, name: "Run A", provider: provider_a) }
    before(:each) { create(:repeating_run, :biweekly, :tomorrow, name: "Run C", provider: provider_a) }
    
    it 'name must be unique among daily runs by date and provider' do
      valid_run_diff_name = build(:repeating_run, :weekly, :tomorrow, name: "Run B", provider: provider_a)
      valid_run_diff_provider = build(:repeating_run, :weekly, :tomorrow, name: "Run A", provider: provider_b)
      valid_run_diff_date = build(:repeating_run, :weekly, :next_week, name: "Run A", provider: provider_a)
      invalid_run_same_date = build(:repeating_run, :weekly, :tomorrow, name: "Run A", provider: provider_a)
      valid_run_zipper = build(:repeating_run, :biweekly, 
                                start_date: Date.tomorrow - 1.week, 
                                name: "Run A", provider: provider_a)
      invalid_run_collision = build(:repeating_run, :weekly, 
                                start_date: Date.tomorrow - 1.week, 
                                name: "Run A", provider: provider_a)
      
      expect(valid_run_diff_name.valid?).to be true
      expect(valid_run_diff_provider.valid?).to be true
      expect(valid_run_diff_date.valid?).to be true
      expect(invalid_run_same_date.valid?).to be false
      expect(valid_run_zipper.valid?).to be true
      expect(invalid_run_collision.valid?).to be false      
    end
    
    it 'name must be unique among repeating runs by date and provider' do
      valid_run_diff_name     = build(:repeating_run, :weekly, :tomorrow, name: "Run D", provider: provider_a)
      valid_run_diff_provider = build(:repeating_run, :weekly, :tomorrow, name: "Run C", provider: provider_b)
      valid_run_diff_date     = build(:repeating_run, :weekly, :next_week, name: "Run C", provider: provider_a)
      invalid_run_same_date   = build(:repeating_run, :weekly, :tomorrow, name: "Run C", provider: provider_a)
      valid_run_zipper        = build(:repeating_run, :biweekly, 
                                  start_date: Date.tomorrow - 1.week, 
                                  name: "Run C", provider: provider_a)
      invalid_run_collision   = build(:repeating_run, :triweekly, 
                                  start_date: Date.tomorrow - 1.week, 
                                  name: "Run C", provider: provider_a)
            
      expect(valid_run_diff_name.valid?).to be true
      expect(valid_run_diff_provider.valid?).to be true
      expect(valid_run_diff_date.valid?).to be true
      expect(invalid_run_same_date.valid?).to be false
      expect(valid_run_zipper.valid?).to be true
      expect(invalid_run_collision.valid?).to be false
    end
    
    it 'at least one day of the week must be checked' do
      valid_one_day   = build(:repeating_run, :no_repeating_days,
                              repeats_mondays: true)
      valid_many_days = build(:repeating_run, :no_repeating_days,
                              repeats_tuesdays: true, repeats_wednesdays: true, repeats_thursdays: true)
      invalid_no_days = build(:repeating_run, :no_repeating_days)
      
      expect(valid_one_day.valid?).to be true
      expect(valid_many_days.valid?).to be true
      expect(invalid_no_days.valid?).to be false
    end
    
  end
  
end
