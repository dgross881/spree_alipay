require 'alipay'

module Spree
  class Gateway::AlipayProvider
    attr_accessor :service
   
    def initialize( options = {})
      ::Alipay.pid = options[:partner]
      ::Alipay.key = options[:sign]
      #::Alipay.seller_email = options[:email]
      self.service =  options[:service]
    end  
    
    def verify?( notify_params )
      ::Alipay::Notify.verify?(notify_params)
    end  
    
    def url( options )
      if trade_create_by_buyer?
        ::Alipay::Service.trade_create_by_buyer_url( options )
      else
        ::Alipay::Service.create_partner_trade_by_buyer_url( options )
      end
    end
    
    def send_goods_confirm( alipay_transaction )
      options = {  :trade_no  => alipay_transaction.trade_no,
        :logistics_name => 'dalianshops.com',
        :transport_type => 'EXPRESS'
      }
      if trade_create_by_buyer? || create_partner_trade_by_buyer?   
        alipay_return = ::Alipay::Service.send_goods_confirm_by_platform(options)
        alipay_xml_return = AlipayXmlReturn.new( alipay_return )
        if alipay_xml_return.success?
          alipay_transaction.update_attributes( :trade_status => alipay_xml_return.trade_status )
        end        
      end      
    end
    
    def refund(payment, amount)
      refund_type = payment.amount == amount.to_f ? "Full" : "Partial"
      batch_no = Alipay::Utils.generate_batch_no

      refund_transaction = Alipay::Service.refund_fastpay_by_platform_pwd_url(
        batch_no: batch_no,
        RefundType: refund_type,
        data:  [{
          trade_no: payment.trade_no,
          amount: amount,
          reason: "REFUND_REASON",
        }],
          :notify_url: admin_order_payment_path(payment.order, payment) 
      )
      refund_transaction_response = provider.refund_transaction(refund_transaction)

      if refund_transaction_response.success?
        payment.source.update_attributes({
          :refunded_at => Time.now,
          :batch_no => refund_transaction_response.batch_no,
          :state => "refunded",
          :refund_status => refund_type
        })

        payment.class.create!(
          :trade_no => payment.order,
          :source => payment,
          :payment_type => payment.payment_method,
          :total_fee => amount.to_f.abs * -1,
          #:response_code => refund_transaction_response.batch_no,
          :state => 'completed'
        )
      end
      refund_transaction_response
    end
    
    # 标准双接口
    def trade_create_by_buyer?
      self.service == 'trade_create_by_buyer'
    end
    
    # 即时到帐
    def create_direct_pay_by_user?
      self.service == 'create_direct_pay_by_user'      
    end
    
    # 担保交易
    def create_partner_trade_by_buyer?
      self.service == 'create_partner_trade_by_buyer'      
    end
  end
end
