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
end
