class UpgradeController < ApplicationController
  def show
    @checkout_url = Rails.application.credentials.dig(:ls, :checkout_url)
  end
end
