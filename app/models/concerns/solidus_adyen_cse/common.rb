module SolidusAdyenCse
  module Common
    extend ActiveSupport::Concern

    private

    def transaction_amount(currency, amount)
      { currency: currency, value: amount }
    end

    def adyen_options(options = {})
      { recurring: false }.merge(options)
    end

    def adyen_shopper(options)
      { reference: adyen_shopper_reference(options),
        email: options[:email],
        ip: options[:ip],
        statement: "Order ##{options[:order_id]}" }
    end

    def adyen_shopper_reference(options)
      if options[:customer_id].present?
        options[:customer_id]
      else
        options[:email]
      end
    end
  end
end
