module Spree
    # start from Spree 3.0, class Gateway is removed
    class Gateway::AlipayBase < PaymentMethod
      # response_code -> trade_no:trade_status
      ServiceEnum = Struct.new( :trade_create_by_buyer,
        :create_direct_pay_by_user,
        :create_partner_trade_by_buyer,
        :alipay_wap, :create_forex_trade)[ 'trade_create_by_buyer', 'create_direct_pay_by_user', 'create_partner_trade_by_buyer', 'alipay.wap.create.direct.pay.by.user', 'create_forex_trade']

      def service
        raise 'You must implement service method for alipay service'
      end

      # disable source for now
      def source_required?
        false
      end

      def empty_success
        Class.new do
          def success?; true; end
          def authorization; nil; end
        end.new
      end  

      def cancel(response)
        empty_success
      end  
    end
end
