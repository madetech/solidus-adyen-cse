module SolidusAdyenCse
  class Engine < Rails::Engine
    require 'adyen'
    require 'solidus_core'

    isolate_namespace Spree

    engine_name 'solidus_adyen_cse'

    config.generators do |g|
      g.test_framework :rspec
    end

    initializer 'spree.solidus_adyen_cse.payment_methods', after: 'spree.register.payment_methods' do |app|
      app.config.spree.payment_methods << ::Spree::Gateway::AdyenCse
    end

    initializer 'solidus_adyen_cse.assets.precompile', group: :all do |app|
      app.config.assets.precompile += %w( encrypt.adyen.js )
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      Rails.configuration.action_dispatch.parameter_filter = [:encrypted_data]

      Spree::Order.include(SolidusAdyenCse::OrderCheckoutModifier)
      Spree::Order.prepend(SolidusAdyenCse::OrderModifier)
      Spree::Payment.include(SolidusAdyenCse::PaymentModifier)
    end

    config.to_prepare(&method(:activate).to_proc)
  end
end
