module Spree
  class Gateway
    class AdyenCse < Gateway
      include SolidusAdyenCse::Common

      preference :api_username, :string
      preference :api_password, :string
      preference :merchant_account, :string
      preference :public_key, :string
      preference :three_d_secure, :string, default: false

      def auto_capture?
        false
      end

      def method_type
        'adyen_cse'
      end

      def payment_profiles_supported?
        false
      end

      def use_3d_secure?
        three_d_secure
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
        %w(capture credit void)
      end

      def authorize(money, response, options = {})
        card_details = { encrypted: { json: response.encrypted_data } }

        authorize_card(money, response, options, card_details)
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

      def void(response_code, _credit_card, _options = {})
        response = provider.cancel_payment(response_code)

        if response.success?
          def response.authorization; psp_reference; end
        else
          def response.to_s
            "#{result_code} - #{refusal_reason}"
          end
        end
        response
      end

      private

      def authorize_card(money, response, options, card_details)
        response = authorize_payment(money, response, options, card_details)

        if response.success?
          def response.authorization; psp_reference; end

          def response.avs_result; {}; end

          def response.cvv_result; { 'code' => result_code }; end
        else
          def response.to_s; "#{result_code} - #{refusal_reason}"; end
        end

        response
      end

      def authorize_payment(money, _response, options, card_details)
        reference = options[:order_id]

        provider.authorise_payment(reference,
                                   transaction_amount(options[:currency], money),
                                   adyen_shopper(options),
                                   card_details,
                                   adyen_options)
      end
    end
  end
end
