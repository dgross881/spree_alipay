Spree::OrderUpdater.class_eval do 
  def update_payment_state
    alipay_base_class = Spree::Gateway::AlipayBase

    last_state = order.payment_state
    if payments.present? && payments.valid.size == 0
      order.payment_state = 'failed'
    elsif order.state == 'canceled' && order.payment_total == 0
      order.payment_state = 'void'
    else
      order.payment_state = 'balance_due' if order.outstanding_balance > 0 && !order.payments.last.payment_method.kind_of?(alipay_base_class)
      order.payment_state = 'credit_owed' if order.outstanding_balance < 0
      order.payment_state = 'paid' if !order.outstanding_balance? || order.payments.last.payment_method.kind_of?(alipay_base_class)
    end
    order.state_changed('payment') if last_state != order.payment_state
    order.payment_state
  end
end
