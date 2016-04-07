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

      def capture(money, response_code, options = {})
        response = provider.capture_payment(response_code,
                                            transaction_amount(options[:currency], money))

        if response.success?
          def response.authorization; response_code; end # Preserve original psp_reference for refunds

          def response.avs_result; {}; end

          def response.cvv_result; {}; end
        else
          def response.to_s; "#{result_code} - #{refusal_reason}"; end
        end

        response
      end

      # This method will need to accept more arguements when/if payment profiles supported
      # money, credit_card, response_code, options
      def credit(money, response_code, options)
        currency = options[:currency] || options[:originator].payment.currency

        response = provider.refund_payment(response_code,
                                           transaction_amount(currency, money))

        if response.success?
          def response.authorization; psp_reference; end
        else
          def response.to_s; refusal_reason; end
        end

        response
      end

      def cancel(response_code)
        response = provider.cancel_payment(response_code)

        if response.success?
          def response.authorization; psp_reference; end
        else
          def response.to_s; "#{result_code} - #{refusal_reason}"; end
        end

        response
      end

      def void(response_code, _credit_card, _options = {})
        cancel(response_code)
      end

      private

      def authorize_card(money, source, options, card_details)
        response = authorize_payment(money, source, options, card_details)

        if response.success?
          def response.authorization; psp_reference; end

          def response.avs_result; {}; end

          def response.cvv_result; { 'code' => result_code }; end
        else
          def response.to_s; "#{result_code} - #{refusal_reason}"; end
        end

        response
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
    end
  end
end
