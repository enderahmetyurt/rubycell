class UpgradeController < ApplicationController
  def show
    variant_id = ENV["LEMONSQUEEZY_VARIANT_ID"]
    @checkout_url = "https://lemonsqueezy.com/checkout/#{variant_id}" if variant_id.present?
  end
end
