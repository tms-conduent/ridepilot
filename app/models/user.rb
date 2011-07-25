class User < ActiveRecord::Base
  
  has_many   :roles
  has_one    :device_pool_user
  belongs_to :current_provider, :class_name=>"Provider", :foreign_key => :current_provider_id
  belongs_to :driver

  
  validates :password, :confirmation => true
  validates :email, :uniqueness => true
  validates :driver_id, :uniqueness => {:allow_nil => true}

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, 
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  model_stamper
  
  before_create do
    self.email.downcase! if self.email
  end
  
  def self.find_for_authentication(conditions) 
    conditions[:email].downcase! 
    super(conditions) 
  end
  
  def update_password(params)
    unless params[:password].blank?
      self.update_with_password(params)
    else
      self.errors.add('password', :blank)
      false
    end
  end
end
