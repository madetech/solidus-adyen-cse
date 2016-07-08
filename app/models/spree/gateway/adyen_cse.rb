module Spree
  class Gateway
    class AdyenCse < Gateway
      include SolidusAdyenCse::Common

      preference :api_username, :string
      preference :api_password, :string
      preference :merchant_account, :string
      preference :public_key, :string

      def auto_capture?
        true
      end

      def method_type
        'adyen_cse'
      end

      def payment_profiles_supported?
        false
      end

      def provider_class
        ::Adyen::API
      end

      def provider
        ::Adyen.configuration.api_username = preferred_api_username
        ::Adyen.configuration.api_password = preferred_api_password
        ::Adyen.configuration.default_api_params[:merchant_account] = preferred_merchant_account

        @provider ||= provider_class
      end

      def payment_source_class
        CreditCard
      end

      # Gateway Methods

      def actions
        %w(credit void)
      end

      # We can't persist the encrypted_data, so we have to authorize early
      def authorize(money, source, options = {})
        card_details = { encrypted: { json: source.encrypted_data } }

        authorize_card(money, source, options, card_details)
      end

      # Authorization happens between payment -> confirm so we'll capture on complete?
      def purchase(money, source, options = {})
        order_number, payment_number = options[:order_id].split('-')

        order = Spree::Order.find_by(number: order_number)

        payment = Spree::Payment.find_by!(
          order_id: order.id,
          payment_method_id: source.payment_method_id, # Maybe a moo assertion
          number: payment_number
        )

        capture(money, payment.response_code, options)
      end

      # Need to preserve original auth'd psp_reference stored on payment for refunds
      def capture(money, response_code, options = {})
        response = provider.capture_payment(response_code, transaction_amount(options[:currency], money))

        handle_response(response, response_code)
      end

      # This method will need to accept more arguements when/if payment profiles supported
      # money, credit_card, response_code, options
      def credit(money, response_code, options)
        currency = options[:currency] || options[:originator].payment.currency

        response = provider.refund_payment(response_code, transaction_amount(currency, money))

        handle_response(response, response.psp_reference)
      end

      def cancel(response_code)
        response = provider.cancel_payment(response_code)

        handle_response(response, response.psp_reference)
      end

      def void(response_code, _credit_card, _options = {})
        cancel(response_code)
      end

      private

      def authorize_card(money, source, options, card_details)
        response = authorize_payment(money, source, options, card_details)

        handle_response(response, response.psp_reference)
      end

      # https://github.com/wvanbergen/adyen/blob/master/lib/adyen/api.rb#L156
      def authorize_payment(money, _source, options, card_details)
        reference = options[:order_id]

        provider.authorise_payment(reference,
                                   transaction_amount(options[:currency], money),
                                   adyen_shopper(options),
                                   card_details,
                                   false)
      end

      def handle_response(response, original_reference)
        ActiveMerchant::Billing::Response.new(
          response.success?,
          message(response),
          {},
          authorization: original_reference
        )
      end

      def message(response)
        if response.success?
          response.try(:result_code)
        else
          translation = ::SolidusAdyenCse::RefusalReasonTranslation.new(response.refusal_reason)

          Spree.t(translation.key, scope: 'adyen_cse.gateway_errors', default: translation.default_text)
        end
      end
    end
  end
end
