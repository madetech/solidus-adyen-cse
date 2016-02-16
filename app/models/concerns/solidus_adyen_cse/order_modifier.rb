module SolidusAdyenCse
  module OrderModifier
    extend ActiveSupport::Concern

    def unprocessed_payments
      payments.select { |payment| ['checkout', 'adyen_authorized'].include?(payment.state) }
    end
  end
end
