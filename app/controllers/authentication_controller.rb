include AuthenticationHelper
class AuthenticationController < ApplicationController
  def login_redirect_target
    if user_signed_in?
      flash[:error] = "You're already signed in."
      redirect_to root_path and return
    end

    token = access_token_from_code(params[:code], AppConfig["stack_exchange"]["login_redirect_uri"])
    access_token_info = info_for_access_token(token)

    user = User.find_by_stack_exchange_account_id(access_token_info["account_id"])

    if user.present?
      flash[:success] = "Successfully logged in as #{user.username}"
      sign_in_and_redirect user
    else
      user = User.new(stack_exchange_account_id: access_token_info["account_id"])

      user.username = user.get_username(token)
      user.password = user.password_confirmation = SecureRandom.hex

      user.save!

      Thread.new do
        # Do this in the background to keep the page load fast.
        user.update_chat_ids
        user.save!
      end

      flash[:success] = "New account created for #{user.username}. Have fun!"
      sign_in_and_redirect user
    end 
  end
end
