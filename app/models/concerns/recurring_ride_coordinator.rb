require 'active_support/concern'

module RecurringRideCoordinator
  extend ActiveSupport::Concern

  DAYS_OF_WEEK = %w{monday tuesday wednesday thursday friday saturday sunday}

  included do
    before_validation   :update_schedule_attributes
    before_save    :instantiate_recurring_ride_coordinators

    DAYS_OF_WEEK.each do |day|
      define_method "repeats_#{day}s=" do |value|
        instance_variable_set "@repeats_#{day}s", (value == "1" || value == true)
      end

      define_method "repeats_#{day}s" do
        if instance_variable_get("@repeats_#{day}s").nil?
          instance_variable_set "@repeats_#{day}s", self.schedule_attributes.send(day) == 1
        else
          instance_variable_get("@repeats_#{day}s")
        end
      end
    end
  end
  
  module ClassMethods
    attr_reader :occurrence_attribute_block
    attr_reader :occurrence_destroy_future_recurring_ride_coordinators_block
    attr_reader :occurrence_destroy_all_future_recurring_ride_coordinators_block
    attr_reader :occurrence_unlink_past_recurring_ride_coordinators_block

    private

    # Setup method for including class. 
    #     with_attributes: A proc that accepts one argument, the coordinator 
    #       itself (i.e. a trip or run), to be called by 
    #       #recurring_ride_coordinator_attributes
    #     destroy_future_occurrences_with: A proc that accepts one argument, 
    #       the coordinator itself (i.e. a trip or run), to be called by
    #       #destroy_future_recurring_ride_coordinators
    #     unlink_past_occurrences_with: A proc that accepts one argument, the 
    #       coordinator itself (i.e. a trip or run), to be called by 
    #       #unlink_past_recurring_ride_coordinators
    #     class_name: (optional) A string representing the class name of the 
    #       associated scheduler if it can't be inferred from the association 
    #       argument
    def schedules_occurrences_with(with_attributes:, destroy_future_occurrences_with:, destroy_all_future_occurrences_with:, unlink_past_occurrences_with:, class_name: nil)
      @occurrence_attribute_block = with_attributes
      @occurrence_destroy_future_recurring_ride_coordinators_block = destroy_future_occurrences_with
      @occurrence_destroy_all_future_recurring_ride_coordinators_block = destroy_all_future_occurrences_with
      @occurrence_unlink_past_recurring_ride_coordinators_block = unlink_past_occurrences_with
    end
  end

  # Set the interval in schedule attributes
  def repetition_interval=(value)
    self.set_schedule_attribute(:interval, value.to_i)
  end

  def repetition_interval
    self.schedule_attributes[:interval].to_i
  end
  
  # Returns the first day in the current scheduler window: Either tomorrow, or
  # the last day the scheduler has been run for, whichever comes last
  def scheduler_window_start
    [(Date.today.in_time_zone + 1.day), self.try(:scheduled_through)].compact.max
  end
    
  # Returns the last day in the current scheduler window
  def scheduler_window_end
    Date.today.in_time_zone.advance(
      days: ( provider.try(:advance_day_scheduling) ||
              Provider::DEFAULT_ADVANCE_DAY_SCHEDULING)
    )
  end
  
  private

  def update_schedule_attributes
    self.schedule_attributes = recurring_ride_coordinator_attributes
  end

  def instantiate_recurring_ride_coordinators
    self.try(:instantiate!)
  end

  def destroy_future_recurring_ride_coordinators
    self.class.occurrence_destroy_future_recurring_ride_coordinators_block.call self
  end

  def destroy_all_future_recurring_ride_coordinators
    self.class.occurrence_destroy_all_future_recurring_ride_coordinators_block.call self
  end

  def unlink_past_recurring_ride_coordinators
    self.class.occurrence_unlink_past_recurring_ride_coordinators_block.call self
  end

  def recurring_ride_coordinator_attributes
    self.class.occurrence_attribute_block.call self
  end  
end
