require 'spec_helper'
#copy from https://raw.github.com/radar/better_spree_paypal_express/master/spec/features/paypal_spec.rb
#http://sandbox.alipaydev.com/index.htm
#sandbox_areq22@aliyun.com
#http://openapi.alipaydev.com/gateway.do
describe "Alipay", :js => true, :type => :feature do
  let!(:country) { create(:country, :states_required => true) }
  let!(:state) { create(:state, :country => country) }
  let!(:product) { FactoryGirl.create(:product, :name => 'iPad') }

  before do
    @gateway = Spree::Gateway::AlipayEscrow.create!({
      preferred_partner: '2088002627298374',
      preferred_sign: 'f4y25qc539qakg734vn2jpqq6gmybxoz',
      name: "Alipay",
      active: true,
    })
    FactoryGirl.create(:shipping_method)
  end

  let!(:zone) { create(:zone) }

 def fill_in_billing
    fill_in :order_bill_address_attributes_firstname, with: "Test"
    fill_in :order_bill_address_attributes_lastname, with: "User"
    fill_in :order_bill_address_attributes_address1, with: "1 User Lane"
    # City, State and ZIP must all match for PayPal to be happy
    fill_in :order_bill_address_attributes_city, with: "Adamsville"
    select "United States of America", from: :order_bill_address_attributes_country_id
    select "Alabama", from: :order_bill_address_attributes_state_id
    fill_in :order_bill_address_attributes_zipcode, with: "35005"
    fill_in :order_bill_address_attributes_phone, with: "555-123-4567"
  end

    stub_authorization!

    context "refunding payments" do

      before do
        visit spree.root_path
        click_link 'iPad'
        click_button 'Add To Cart'
        click_button 'Checkout'
        within("#guest_checkout") do
          fill_in "Email", with: "test@example.com"
          click_button 'Continue'
        end
        fill_in_billing
        click_button "Save and Continue"
        # Delivery step doesn't require any action
        click_button "Save and Continue"
      end


      it "It shows Alipay Escrow as a source of payment" do
        within '#payment-method-fields' do
          expect(page).to have_content "Alipay"
        end
      end

      it "Choose alipay for paymnet and expect the correct success message" do 
         choose "Alipay"
         click_button "Save and Continue"
         expect(page).to have_content "Success" 
      end
    end 
  end 
