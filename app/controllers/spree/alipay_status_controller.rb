#inspired by https://github.com/spree-contrib/spree_skrill
module Spree
  class AlipayStatusController < StoreController
    #fixes Action::Controller::InvalidAuthenticityToken error on alipay_notify 
    skip_before_action :verify_authenticity_token
      
    def alipay_done
      # alipay acount could vary in each store. 
      # get order_no from query string -> get payment -> initialize Alipay -> verify ailpay callback
      order = retrieve_order params["out_trade_no"]      
      alipay_payment = get_alipay_payment( order )     
       
      if alipay_payment.payment_method.provider.verify?( request.query_parameters )
        complete_order( order )
        if order.complete?
          #copy from spree/frontend/checkout_controller
          session[:order_id] = nil
          flash.notice = Spree.t(:order_processed_successfully)
          flash['order_completed'] = true
          redirect_to spree.order_path( order, utm_nooverride: 1 )
        else
          #Strange
          redirect_to checkout_state_path(order.state, utm_nooverride: 1)
        end
      else
        redirect_to checkout_state_path(order.state, utm_nooverride: 1)          
      end
    end

    def alipay_notify
      order = retrieve_order params["out_trade_no"]      
      alipay_payment = get_alipay_payment( order )     
      if alipay_payment.payment_method.provider.verify?( request.request_parameters )
        if request[:trade_status] == "WAIT_SELLER_SEND_GOODS"
          complete_order( order )
          render text: "success"
        else 
          render text: "Buyer needs to pay"
        end 
      else
        render text: "fail"         
      end
    end

    private

    def retrieve_order(order_number)
      @order = Spree::Order.find_by_number!(order_number)
    end    

    def get_alipay_payment( order )
      #use payment instead of unprocessed_payments, order may be completed.
      order.payments.last
    end
    
    def complete_order( order )
      unless order.complete?
        alipay_payment = order.unprocessed_payments.last
        # payment.state always :complete for both service, payment.source store more detail
        alipay_transaction = AlipayTransaction.create_from_postback params     
        alipay_payment.source = alipay_transaction
        alipay_payment.save!
        # it require pending_payments to process_payments!
        order.next
      end
    end
  end
end
