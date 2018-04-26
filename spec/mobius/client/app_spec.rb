RSpec.describe Mobius::Client::App do
  subject(:app) { described_class.new(seed, address) }

  let(:seed) { "SBCZGBNEGLJ5MXG6H6J5HCVZ4ACYAZ7BZOEK6TJENF7ADEVSX2X37XMG" }
  let(:address) { "GBTYV66THKPJR4UU5ZHONLRZJKWGGVOCYWVYOTWKJU75VN54K26C5VYG" }

  describe "#pay" do
    context "when balance is sufficient" do
      it do
        VCR.use_cassette("app/app_pay") do
          expect { app.pay(5) }.not_to raise_error
        end
      end
    end

    context "when balance is insufficient" do
      it do
        VCR.use_cassette("app/app_pay_insufficient_funds") do
          expect { app.pay(2**20) }.to raise_error Mobius::Client::Error::InsufficientFunds
        end
      end
    end
  end

  it "#balance" do
    VCR.use_cassette("app/app_balance") do
      expect(app.balance).to eq(995)
    end
  end

  describe "#transfer" do
    context "when everything is correct" do
      let(:target) { "GCOCYI2CTR2NH4QNJXTND7EHRLD7U3WZBR63OMVTZM4AXGZ4FIL2XR2Y" }

      it do
        VCR.use_cassette("app/app_transfer_correct") do
          expect { app.transfer(5, target) }.not_to raise_error
        end
      end
    end

    context "when target account is missing" do
      let(:target) { "GDJ6SJ6537LIPUFE6CTYHVCIW3GUURXTN5YLYR5W2QDHQM4HIDQZING3" }

      it do
        VCR.use_cassette("app/app_transfer_account_missing") do
          expect { app.transfer(5, target) }.to raise_error Mobius::Client::Error::AccountMissing
        end
      end
    end

    context "when trustline is missing on target account" do
      let(:target) { "GDJOTJBFZ4UVHHR7CMO55W64ZLYBPVX5W3VKC7D5OFIOZUEKL5Q2YRB3" }

      it do
        VCR.use_cassette("app/app_transfer_trustline_missing") do
          expect { app.transfer(5, target) }.to raise_error Mobius::Client::Error::TrustlineMissing
        end
      end
    end
  end
end
