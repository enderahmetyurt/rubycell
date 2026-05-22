class UpgradeController < ApplicationController
  def show
    @checkout_url = "https://lemonsqueezy.com/checkout/#{ENV.fetch("LEMONSQUEEZY_VARIANT_ID", "")}"
  end
end
