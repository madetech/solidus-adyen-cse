module SolidusAdyenCse
  module CheckoutModifier
    extend ActiveSupport::Concern

    included do
      attr_accessor :encrypted_card_data

      state_machine.before_transition to: :confirm,
                                      do: :authorize_adyen_cse_payments_before_confirm!
    end

    def authorize_adyen_cse_payments_before_confirm!
      return if !payment_required?

      if authorize_adyen_cse_payments!
        true
      else
        saved_errors = errors[:base]
        saved_errors.each { |error| errors.add(:base, error) }
        false
      end
    end

    def unprocessed_adyen_cse_payments
      @unprocessed_adyen_cse_payments ||= payments.includes(:payment_method).where(spree_payment_methods: {
        type: 'Spree::Gateway::AdyenCse'
      }).select(&:checkout?)
    end

    def authorize_adyen_cse_payments!
      authorize_adyen_cse_payments
    end

    private

    def encrypted_data_for_payment_source(payment_method_id)
      encrypted_card_data[payment_method_id.to_s.to_sym] || ''
    end

    def process_adyen_cse_payments
      unprocessed_adyen_cse_payments.each do |payment|
        break if payment_total >= total

        unless payment.source.encrypted_data = encrypted_data_for_payment_source(payment.payment_method_id)
          raise_gateway_error('adyen_cse.errors.missing_encrypted_data')
        end

        payment.public_send(:adyen_cse_authorize!)

        increment_payment_total(payment.amount) if payment.completed?
      end
    end

    def authorize_adyen_cse_payments
      return true if payment_total >= total

      raise raise_gateway_error(:no_payment_found) if unprocessed_adyen_cse_payments.empty?

      process_adyen_cse_payments
    rescue Spree::Core::GatewayError => e
      result = !!Spree::Config[:allow_checkout_on_gateway_error]
      errors.add(:base, e.message) && (return result)
    end
  end

  def raise_gateway_error(translation_key)
    raise Spree::Core::GatewayError.new(translation_key)
  end

  def increment_payment_total(amount)
    self.payment_total += amount
  end
end
