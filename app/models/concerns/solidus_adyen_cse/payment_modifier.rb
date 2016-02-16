module SolidusAdyenCse
  module PaymentModifier
    extend ActiveSupport::Concern

    included do
      scope :adyen_authorized, -> { with_state('adyen_authorized') }

      state_machine.before_transition to: :invalid,
                                      do: :cancel_old_adyen_cse_payment

      state_machine.event :adyen_authorize do
        transition from: [:checkout, :processing], to: :adyen_authorized
      end

      state_machine.event :started_processing do
        transition from: [:checkout, :pending, :completed, :adyen_authorized, :processing], to: :processing
      end

      state_machine.event :complete do
        transition from: [:processing, :pending, :checkout, :adyen_authorized], to: :completed
      end

      state_machine.event :invalidate do
        transition from: [:adyen_authorized, :checkout], to: :invalid
      end

      after_create :cancel_old_adyen_cse_payments
    end

    def adyen_cse_payment?
      payment_method.type.eql?('Spree::Gateway::AdyenCse')
    end

    def adyen_cse_authorize!
      handle_payment_preconditions { process_cse_authorization }
    end

    private

    def cancel_old_adyen_cse_payments
      return if store_credit? && %w( invalid failed ).include?(state)

      order.payments.adyen_authorized.where(payment_method: payment_method)
        .where.not(id: id)
        .each(&:invalidate!)
    end

    def process_cse_authorization
      started_processing!
      gateway_action(source, :authorize, :adyen_authorize)
    end

    def cancel_old_adyen_cse_payment
      return unless adyen_cse_payment?
      return true if response_code.blank?

      payment_method.cancel(response_code)
      true
    end
  end
end
