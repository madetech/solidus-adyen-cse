module Spree
  class Gateway
    class AdyenCse < Gateway
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
      end

      def credit(money, _credit_card, _response_code, options = {})
      end

      def void(_response_code, _credit_card, options = {})
      end

      private

      def authorize_card(money, response, options, card_details)
        response = authorize_payment(money, response, options, card_details)

        puts response

        if response.success?
          def response.authorization; psp_reference; end

          def response.avs_result; {}; end

          def response.cvv_result; { 'code' => result_code }; end
        else
          def response.to_s
            "#{result_code} - #{refusal_reason}"
          end
        end

        response
      end

      def authorize_payment(money, _response, options, card_details)
        reference = options[:order_id]
        amount = { currency: options[:currency], value: money }

        provider.authorise_payment(reference,
                                   amount,
                                   adyen_shopper(options),
                                   card_details,
                                   adyen_options)
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
end
