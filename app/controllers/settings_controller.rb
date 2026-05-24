class SettingsController < ApplicationController
  def show
    @user = Current.user
  end

  def resend_confirmation
    @user = Current.user
    if @user.confirmed?
      redirect_to settings_path, notice: "Email already confirmed."
    else
      @user.update!(confirmation_token: SecureRandom.urlsafe_base64(32))
      ConfirmationMailer.confirmation(@user).deliver_later
      redirect_to settings_path, notice: "Confirmation email sent! Check your inbox."
    end
  end

  def update
    @user = Current.user
    if @user.update(settings_params)
      redirect_to settings_path, notice: "Settings updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    params.require(:user).permit(:language, :frequency)
  end
end
