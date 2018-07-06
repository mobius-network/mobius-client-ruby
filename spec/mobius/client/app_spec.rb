RSpec.describe Mobius::Client::App do
  subject(:app) { described_class.new(seed, address) }

  let(:seed) { "SBCZGBNEGLJ5MXG6H6J5HCVZ4ACYAZ7BZOEK6TJENF7ADEVSX2X37XMG" }
  let(:address) { "GBTYV66THKPJR4UU5ZHONLRZJKWGGVOCYWVYOTWKJU75VN54K26C5VYG" }

  describe "#charge" do
    context "when balance is sufficient" do
      it "transfers money from user's account to app account" do
        VCR.use_cassette("app/app_charge") do
          check_deltas(app_delta: 5, user_delta: -5) { app.charge(5) }
        end
      end
    end

    context "when target address is given" do
      let(:target) { "GCOCYI2CTR2NH4QNJXTND7EHRLD7U3WZBR63OMVTZM4AXGZ4FIL2XR2Y" }
      let(:target_account) { Mobius::Client::Blockchain::Account.new(target) }

      it "transfers money from user's account to target address" do
        VCR.use_cassette("app/app_charge_with_target") do
          check_deltas(app_delta: 0, user_delta: -5, target_delta: 5) do
            app.charge(5, target_address: target)
          end
        end
      end
    end

    context "when balance is insufficient" do
      it do
        VCR.use_cassette("app/app_charge_insufficient_funds") do
          expect { app.charge(2**20) }.to raise_error Mobius::Client::Error::InsufficientFunds
        end
      end
    end

    context "when amount is NaN" do
      it do
        expect { app.charge("1.2s") }.to raise_error Mobius::Client::Error::InvalidAmount
      end
    end
  end

  it "#balance" do
    VCR.use_cassette("app/app_balance") do
      expect(app.user_balance).to eq(995)
    end
  end

  describe "#transfer" do
    let(:target) { "GCOCYI2CTR2NH4QNJXTND7EHRLD7U3WZBR63OMVTZM4AXGZ4FIL2XR2Y" }
    let(:target_account) { Mobius::Client::Blockchain::Account.new(target) }

    context "when everything is correct" do
      it "transfers money from app account to target" do
        VCR.use_cassette("app/app_transfer_correct") do
          check_deltas(app_delta: 0, user_delta: -5, target_delta: 5) do
            app.transfer(5, target)
          end
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

    context "when amount is NaN" do
      it do
        expect { app.transfer("1.2s", target) }.to raise_error Mobius::Client::Error::InvalidAmount
      end
    end
  end

  describe "#payout" do
    let(:target) { "GCOCYI2CTR2NH4QNJXTND7EHRLD7U3WZBR63OMVTZM4AXGZ4FIL2XR2Y" }
    let(:target_account) { Mobius::Client::Blockchain::Account.new(target) }

    context "when target account is provided" do
      it "transfers money to target from app's account" do
        VCR.use_cassette("app/app_payout_to_target") do
          check_deltas(app_delta: -5, user_delta: 0, target_delta: 5) do
            app.payout(5, target_address: target)
          end
        end
      end
    end

    context "when target account is not provided" do
      it "transfers money to user's account" do
        VCR.use_cassette("app/app_payout_to_user") do
          check_deltas(app_delta: -5, user_delta: 5) { app.payout(5) }
        end
      end
    end

    context "when target account is missing" do
      let(:target) { "GDJ6SJ6537LIPUFE6CTYHVCIW3GUURXTN5YLYR5W2QDHQM4HIDQZING3" }

      it do
        VCR.use_cassette("app/app_payout_account_missing") do
          expect { app.payout(5, target_address: target) }.to raise_error Mobius::Client::Error::AccountMissing
        end
      end
    end

    context "when trustline is missing on target account" do
      let(:target) { "GDJOTJBFZ4UVHHR7CMO55W64ZLYBPVX5W3VKC7D5OFIOZUEKL5Q2YRB3" }

      it do
        VCR.use_cassette("app/app_payout_trustline_missing") do
          expect { app.payout(5, target_address: target) }.to raise_error Mobius::Client::Error::TrustlineMissing
        end
      end
    end

    context "when amount is NaN" do
      it do
        expect { app.payout("1.2s") }.to raise_error Mobius::Client::Error::InvalidAmount
      end
    end
  end
end
