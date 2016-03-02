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
      status = params[:trade_status] 
      handle_status(status, order)

      if order.complete?
        #copy from spree/frontend/checkout_controller
        session[:order_id] = nil
        flash.notice = Spree.t(:order_processed_successfully)
        flash['order_completed'] = true
        get_alipay_payment(order).complete!
        redirect_to spree.order_path( order, utm_nooverride: 1 )
      else
        #Strange
        flash[:error] = "Something seemed to go wrong #{status}"
        redirect_to checkout_state_path(order.state, utm_nooverride: 1)
      end
    end

    def alipay_notify
      order = retrieve_order params["out_trade_no"]
      alipay_payment = get_alipay_payment( order )
      notify_params = params.except(*request.path_parameters.keys)  
      if alipay_payment.payment_method.provider.verify?( notify_params )
        status = params[:trade_status]
        handle_status(status, order)
        render text: "success"
      else
        render text: "fail"
      end
    end

    private


    def handle_status(status, order)
      case status
      when 'WAIT_BUYER_PAY'
        logger.info "Waiting for the payment"
      when 'WAIT_SELLER_SEND_GOODS'
        logger.info "Waiting for the seller to send the goods"
      when 'TRADE_FINISHED', "TRADE_SUCCESS"
       complete_order(order, params.except(*request.path_parameters.keys))
       logger.info "Trade Success"
      when 'TRADE_CLOSED'
        logger.info "Trade closed"
      else
        logger.info "Received status signal: #{status}"
      end
    end


    def retrieve_order(order_number)
      @order = Spree::Order.find_by_number!(order_number)
    end

    def get_alipay_payment( order )
      #use payment instead of unprocessed_payments, order may be completed.
      order.payments.last
    end

    def complete_order( order, alipay_parameters )
      unless order.complete?
        alipay_payment = get_alipay_payment( order )
        alipay_payment.update_attribute :response_code, "#{alipay_parameters['trade_no']}, \n 
                                                         #{alipay_parameters['trade_status']}"
        # it require pending_payments to process_payments!
        order.next 
      end
    end
  end
end
