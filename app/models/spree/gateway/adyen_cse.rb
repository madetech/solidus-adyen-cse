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
      #
      # This is our capture, this does feel quite edgy.
      def purchase(money, source, options = {})
        order = Spree::Order.find_by(number: options[:order_id].split('-')[0])

        payment = Spree::Payment.where(
          order_id: order.id,
          source_id: source.id,
          payment_method_id: source.payment_method_id,
          state: 'processing'
        ).last

        capture(money, payment.response_code, options)
      end

      def capture(money, response_code, options = {})
        response = provider.capture_payment(response_code,
                                            transaction_amount(options[:currency], money))

        if response.success?
          def response.authorization; psp_reference; end

          def response.avs_result; {}; end

          def response.cvv_result; {}; end
        else
          def response.to_s; "#{result_code} - #{refusal_reason}"; end
        end

        response
      end

      def credit(money, _credit_card, response_code, _options = {})
        response = provider.cancel_or_refund_payment(response_code,
                                                     transaction_amount(options[:currency], money))

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
