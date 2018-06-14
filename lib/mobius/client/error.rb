class Mobius::Client::Error < StandardError
  # Raised if stellar account is missing on network
  class AccountMissing < self
    def to_s
      @message || "Stellar account does not exists"
    end
  end

  # Raised if there is insufficient balance for payment
  class InsufficientFunds < self
  end

  # Raised if transaction in question has invalid structure
  class MalformedTransaction < self
  end

  # Raised if transaction has expired.
  class TokenExpired < self
  end

  # Raised if transaction has expired (strict mode).
  class TokenTooOld < self
  end

  # Raises if account does not contain MOBI trustline
  class TrustlineMissing < self
    def to_s
      @message || "Trustline not found"
    end
  end

  # Raises if account does not contain MOBI trustline
  class AuthorisationMissing < self
    def to_s
      @message || "Authorisation missing"
    end
  end

  # Raised in transaction in question has invalid or does not have required signatures
  class Unauthorized < self
    def to_s
      @message || "Given transaction signature invalid"
    end
  end

  # Raised if unknown or empty value has passed to KeyPairFactory
  class UnknownKeyPairType < self
  end

  # Raised, when NaN provided as an amount for payment operation
  class InvalidAmount < self
  end
end
