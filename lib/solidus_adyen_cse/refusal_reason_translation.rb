module SolidusAdyenCse
  class RefusalReasonTranslation
    ERROR_CODE_REGEX = /(?<code>\d{3})\s(?<message>.*)/

    def initialize(refusal_reason)
      @refusal_reason = refusal_reason
    end

    def key
      i18n_translation_key
    end

    def default_text
      i18n_fallback
    end

    private

    def i18n_fallback
      if error_code?
        error[:message]
      else
        @refusal_reason
      end
    end

    def i18n_translation_key
      if error_code?
        error[:code].to_sym
      else
        @refusal_reason.downcase.gsub(/\W/, '').to_sym
      end
    end

    def error
      reason_regex
    end

    def error_code?
      reason_regex.present?
    end

    def reason_regex
      @reason_regex ||= @refusal_reason.match(ERROR_CODE_REGEX)
    end
  end
end
