require 'spec_helper'

describe Spree::Gateway::AlipayEscrow do
  before do
    Spree::Gateway.update_all(active: false)
    @gateway = described_class.create!(name: 'Alipay', active: true)
    @gateway.set_preference(:partner, 'TESTPID')
    @gateway.set_preference(:sign, 'TESTKEY')
    @gateway.save!

    @sign_params = {
      sign_type: 'MD5',
      sign: '22fc7e38e5acdfede396aa463870d111',
      notify_id: '1234'
    }
  end

  let(:payment) {create(:payment, order: order, payment_method: @gateway, amount: 10.00) }
  let(:country) {create(:country, name: 'United States', iso_name: 'UNITED STATES', iso3: 'USA', iso: 'US', numcode: 840)}
  let(:state) {create(:state, name: 'Maryland', abbr: 'MD', country: country)}
      
  let(:address) {create(:address,
        firstname: 'John',
        lastname:  'Doe',
        address1:  '1234 My Street',
        address2:  'Apt 1',
        city:      'Washington DC',
        zipcode:   '20123',
        phone:     '(555)555-5555',
        state:     state,
        country:   country
      )}

  let(:order) {create(:order_with_totals, bill_address: address, ship_address: address)}
      


  describe '.service' do
     it "sets gateway to create_partner_trade_by_buyer" do 
      expect(@gateway.service).to eq "create_partner_trade_by_buyer"
    end
  end
  
  context 'set_partner_trade' do
    it 'generate the partner trade button' do
      options_method 
      binding.pry
      expect(@gateway.provider.url(@options)).to include "https://mapi.alipay.com/gateway.do?service=create_partner_trade_by_buyer&_input_charset=utf-8&partner=TESTPID&seller_id=TESTPID"
    end
  end


  def options_method 
      @options = { :_input_charset => "utf-8", 
                      :out_trade_no => order.number,
                      :price => order.total - order.shipment_total, 
                      :quantity => 1,
                      :logistics_type=> 'EXPRESS', #EXPRESS, POST, EMS
                      :logistics_fee => order.shipments.to_a.sum(&:cost), 
                      :logistics_payment=>'BUYER_PAY',
                      :seller_id => @gateway.preferred_partner,
                      :body => order.products.collect(&:name).to_s,  #String(400)                  
                      :payment_type => 1,
                      :subject =>"订单编号:#{order.number}"                  
                     }
   end
end
