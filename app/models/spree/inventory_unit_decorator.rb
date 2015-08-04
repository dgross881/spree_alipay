Spree::InventoryUnit.class_eval do 
  #calling send_goods_confirm_of_alipy after shippment state transitions to shipped
  state_machine do
    after_transition to: :shipped, do: :send_goods_confirm_for_alipay
  end 
   
   private 
   # Changes Alipay's order state from 等待付款 "waiting for shipments" to 等待确认收货 "wait for confirmation of receipt"
   def send_goods_confirm_for_alipay
      payments_by_alipay = order.payments.completed.select(&:method_alipay?)
      if payments_by_alipay.present?
        payments_by_alipay.each{|pba|
          pba.source.send_goods_confirm
        }
    end
  end
end 
