require 'spec_helper' 

describe Spree::AlipayStatusController do
  describe "Get #alipay_done" do
    it "It sets @friendship to current users following friendship" do
      order = create(:order)
      payment = Spree::AlipayEscrow.create!(name: "Alipay", active: true)
      friendship = Fabricate(:friendship, follower: @user, leader: alice) 
      get :alipay_done  
      expect(assigns(:friendships)).to eq([friendship])
    end

    it_behaves_like 'require_user_sign_in' do
     before { get :index }
    end 
  end 
  
