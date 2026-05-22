class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    if @user.save
      send_confirmation_email(@user)
      redirect_to new_session_path, notice: "Account created! Check your email to confirm your account."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def confirm
    user = User.find_by(confirmation_token: params[:token])
    if user && !user.confirmed?
      user.update!(confirmed: true, confirmation_token: nil)
      start_new_session_for(user)
      redirect_to dashboard_path, notice: "Email confirmed! Welcome to RubyCell."
    else
      redirect_to root_path, alert: "Invalid or expired confirmation link."
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end

  def send_confirmation_email(user)
    ConfirmationMailer.confirmation(user).deliver_later
  end
end
