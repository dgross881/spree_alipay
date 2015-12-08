module Spree
  class Gateway::AlipayForexTrade < Gateway::AlipayDualfun

    def service
      ServiceEnum.create_forex_trade
    end

    def auto_capture?
      return false
    end
  end
end
