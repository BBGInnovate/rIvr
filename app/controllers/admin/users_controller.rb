class Admin::UsersController < ApplicationController

  skip_filter :login_required

  active_scaffold :user do |config|
    config.label = '&nbsp;'
    config.actions.exclude :show
    config.list.sorting = {:name => 'ASC'}
    config.columns = [:name, :login, :role, :email,:telephone, :password_confirmation, :created_at]
    config.columns[:email].label = 'Email *'
    config.columns[:name].label = 'Name *'
    config.columns[:login].label = 'Login *'
    config.columns[:created_at].label = 'Created'
    config.columns[:password].label = 'Password'
    config.columns[:password].form_ui = :password
    config.columns[:password_confirmation].label = 'Confirm Password'
    config.columns[:password_confirmation].form_ui = :password
    # config.create.columns.exclude :my_charities,:user_ip_address
    # config.update.columns.exclude :user_ip_address
    config.search.text_search = :start
    config.search.columns = [:name]
  end
 
# see same method in User model
  def update_authorized?(record=nil)
    current_user.is_admin?
  end 
  def delete_authorized?(record=nil)
    current_user.is_admin?
  end 

end