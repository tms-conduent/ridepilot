class Driver < ActiveRecord::Base
  has_paper_trail
  
  belongs_to :provider
  belongs_to :user
  
  has_one :device_pool_driver, dependent: :destroy
  has_one :device_pool, through: :device_pool_driver

  has_many :operating_hours, class_name: :OperatingHours, dependent: :destroy
  has_many :driver_histories, dependent: :destroy, inverse_of: :driver
  has_many :driver_compliances, dependent: :destroy, inverse_of: :driver
  has_many :documents, as: :documentable, dependent: :destroy

  accepts_nested_attributes_for :driver_histories, allow_destroy: true, reject_if: proc { |attributes| attributes['event'].blank? }
  accepts_nested_attributes_for :driver_compliances, allow_destroy: true, reject_if: proc { |attributes| attributes['event'].blank? }
  accepts_nested_attributes_for :documents, allow_destroy: true, reject_if: :blank_document?
  
  validates :user_id, uniqueness: {allow_nil: true}
  validates :name, uniqueness: {scope: :provider_id}, length: {minimum: 2}
  validates :email, format: {with: Devise.email_regexp, allow_blank: true}

  scope :users,         -> { where("drivers.user_id IS NOT NULL") }
  scope :active,        -> { where(active: true) }
  scope :for_provider,  -> (provider_id) { where(provider_id: provider_id) }
  scope :default_order, -> { order(:name) }
  
  def self.unassigned(provider)
    users.for_provider(provider).reject { |driver| driver.device_pool.present? }
  end

  def hours_hash
    result = {}
    self.operating_hours.each do |h|
      result[h.day_of_week] = h
    end
    result
  end
  
  def available?(day_of_week: Time.current.wday, time_of_day: Time.current.strftime('%H:%M'))
    # If no operating hours are defined, assume available
    return true unless operating_hours.any?

    if hours = operating_hours.where(day_of_week: day_of_week).first
      if hours.is_closed?
        return false
      elsif hours.is_24_hours?
        return true
      elsif hours.start_time > hours.end_time
        return time_of_day >= hours.start_time.strftime('%H:%M') || time_of_day <= hours.end_time.strftime('%H:%M')
      elsif hours.start_time != hours.end_time
        return time_of_day.between? hours.start_time.strftime('%H:%M'), hours.end_time.strftime('%H:%M')
      else
        # Some edge condition...
        false
      end
    else
      # No hours defined for that day, assume unavailable
      false
    end
  end
  
  def compliant?(as_of: Date.current)
    driver_compliances.for(id).overdue(as_of: as_of).empty?
  end
  
  private
  
  def blank_document?(attributes)
    attributes['document_file_name'].blank? ||
      attributes['document_content_type'].blank? ||
      attributes['document_file_size'].blank?
  end
end
