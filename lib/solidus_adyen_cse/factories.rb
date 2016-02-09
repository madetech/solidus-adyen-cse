FactoryGirl.define do
  # Define your Spree extensions Factories within this file to enable applications, and other extensions to use and override them.
  #
  # Example adding this to your spec_helper will load these Factories for use:
  # require 'solidus_adyen_cse/factories'

  factory :adyen_cse_payment_method, class: Spree::Gateway::AdyenCse do
    name 'Credit Card'
    active true
    preferred_api_username ''
    preferred_api_password ''
    preferred_merchant_account ''
    preferred_public_key ''
    preferred_test_mode true
    preferred_three_d_secure ''
  end
end
