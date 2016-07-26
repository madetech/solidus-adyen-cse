FactoryGirl.define do
  # Define your Spree extensions Factories within this file to enable applications, and other extensions to use and override them.
  #
  # Example adding this to your spec_helper will load these Factories for use:
  # require 'solidus_adyen_cse/factories'

  factory :adyen_cse_payment_method, class: Spree::Gateway::AdyenCse do
    name 'Pay with Credit Card'
    active true
    preferred_api_username 'tester'
    preferred_api_password 'example'
    preferred_merchant_account 'testo'
    preferred_public_key '1001_test'
    preferred_test_mode true
  end
end
