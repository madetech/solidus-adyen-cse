module SolidusAdyenCse
  module OrderCheckoutModifier
    extend ActiveSupport::Concern

    included do
      # TODO: Remove once our branch merged
      attr_accessor :encrypted_card_data

      state_machine.before_transition to: :confirm,
                                      do: :authorize_adyen_cse_payments_before_confirm!

      state_machine.before_transition to: :complete,
                                      do: :temporary_card_payment?
    end

    def authorize_adyen_cse_payments_before_confirm!
      return unless payment_required?

      if authorize_adyen_cse_payments!
        true
      else
        false
      end
    end

    def unprocessed_adyen_cse_payments
      payments.includes(:payment_method)
        .where(spree_payment_methods: { type: 'Spree::Gateway::AdyenCse' })
        .select(&:checkout?)
    end

    def authorize_adyen_cse_payments!
      authorize_adyen_cse_payments
    end

    private

    def temporary_card_payment?
      return if valid_credit_cards.blank?
      return unless valid_credit_cards.first.payment_method.type == 'Spree::Gateway::AdyenCse'

      self.temporary_credit_card = true
    end

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

      process_adyen_cse_payments
    rescue Spree::Core::GatewayError => e
      result = !Spree::Config[:allow_checkout_on_gateway_error].blank?
      errors.add(:base, e.message) && (return result)
    end

    def raise_gateway_error(translation_key)
      raise Spree::Core::GatewayError.new(Spree.t(translation_key)), Spree.t(translation_key)
    end

    def increment_payment_total(amount)
      self.payment_total += amount
    end
  end
end
