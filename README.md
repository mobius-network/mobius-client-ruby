# Mobius DApp Store Ruby SDK

The Mobius DApp Store Ruby SDK makes it easy to integrate Mobius DApp Store MOBI payments into any Ruby application.

A big advantage of the Mobius DApp Store over centralized competitors such as the Apple App Store or Google Play Store is significantly lower fees - currently 0% compared to 30% - for in-app purchases.

## DApp Store Overview

The Mobius DApp Store will be an open-source, non-custodial "wallet" interface for easily sending crypto payments to apps. You can think of the DApp Store like https://stellarterm.com/ or https://www.myetherwallet.com/ but instead of a wallet interface it is an App Store interface.

The DApp Store is non-custodial meaning Mobius never holds the secret key of either the user or developer.
   
An overview of the DApp Store architecture is:
   
- Every application holds the private key for the account where it receives MOBI.
- An application specific unique account where a user deposits MOBI for use with the application is generated for each app based on the user's seed phrase.
- When a user opens an app through the DApp Store:
  1) Adds the application's public key as a signer so the application can access the MOBI and
  2) Signs a challenge transaction from the app with its secret key to authenticate that this user owns the account. This prevents a different person from pretending they own the account and spending the MOBI (more below under Authentication).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mobius-client'
```

And then execute:

    $ bundle

Or install it yourself with:

    $ gem install mobius-client

### Setting up the developer's application account

Run:

    $ mobius-cli create dapp_account

Creates a new Stellar account with 1,000 test-net MOBI.

You can also obtain free test network MOBI from https://mobius.network/friendbot

### Setting up test user accounts

1. Create empty Stellar account without a MOBI trustline.
    ```
      $ mobius-cli create account
    ```
2. Create stellar account with 1,000 test-net MOBI
    ```
      $ mobius-cli create dapp_account
    ```
3. Create stellar account with 1,000 test-net MOBI and the specified application public key added as a signer
    ```
      $ mobius-cli create dapp_account -a <Your application public key>
    ```

### Account creation wizard

Below command will create and setup the 4 account types above for testing and generate a simple HTML test interface that simulates the DApp Store authentication functionality (obtaining a challenge request from an app, signing it, and then openining the specified app passing in a JWT encoded token the application will use to verify this request is from the user that owns the specified MOBI account).

```
  $ mobius-cli create dev-wallet
```

## Authentication and Payment

### Explanation

Assume we have two parts: user and application. Every part has it's own Stellar key pair. Application issues session token.

Application wants to ensure that:

* User left token intact (to protect from replay attack).
* Token is received and acknowledged by correct user.

The process is simple:

* User requests challenge from the application.
* Challenge is fake transaction, payment of 1 XLM from and to application account. It never goes to ledger.
* Application generates challenge transaction, signs it with own private key and sends it to user.
* User signs received transaction with own private key and sends it back to application along with public key.
* Application ensures that both signatures are valid, time bounds cover current time and grants user access.

Challenge itself is the transaction because only transactions might be signed by Ledger device.

See demo at:

    $ git clone git@github.com/mobius-network/mobius-client-ruby.git
    $ cd mobius-client-ruby && bundle
    $ cd examples/auth && bundle && ruby auth.rb

### Sample Server Implementation

#### Authentication

```
class AuthController < ActionController::Base
  skip_before_action :verify_authenticity_token, :only => [:authenticate]

  # GET /auth
  def challenge
    # Generates and returns challenge transaction XDR signed by application to user
    render plain: Mobius::Client::Auth::Challenge.call(
      Rails.application.secrets.app[:secret_key], # SA2VTRSZPZ5FIC.....I4QD7LBWUUIK
      12.hours                                    # Session duration
    )
  end

  # POST /auth
  def authenticate
    # Validates challenge transaction. It must be:
    #   - Signed by application and requesting user.
    #   - Not older than 10 seconds from now (see Mobius::Client.strict_interval`)
    token = Mobius::Client::Auth::Token.new(
      Rails.application.secrets.app[:secret_key], # SA2VTRSZPZ5FIC.....I4QD7LBWUUIK
      params[:xdr],                               # Challenge transaction
      params[:public_key]                         # User's public key
    )

    # Important! Otherwise, token will be considered valid.
    token.validate!

    # Converts issued token into JWT and sends it to user.
    #
    # Note: this is not the requirement. Instead of JWT, application might save token.hash along
    # with time frame and public key to local database and validate over it.
    render plain: Mobius::Client::Auth::Jwt.new(
      Rails.application.secrets.app[:jwt_secret]
    ).encode(token)

    rescue Mobius::Client::Error::Unauthorized
      # Signatures are invalid
      render plain: "Access denied!"
    rescue Mobius::Client::Error::TokenExpired
      # Current time is outside session time bounds
      render plain: "Session expired!"
    rescue Mobius::Client::Error::TokenTooOld
      # Challenge transaction was issued more than 10 seconds ago
      render plain: "Challenge tx expired!"
    end
  end
end
```

#### Payment

Now, let's withdraw.

Given that:

* User has access token.
* User has authorised his account to be used by your application.

User opens application page.

```
class AppController < ActionController::Base
  skip_before_action :verify_authenticity_token, :only => [:pay]

  ROUND_PRICE = 5

  # GET /
  def index
    # User has opened application page directly
    return render plain: "Visit https://store.mobius.network/flappy_bird to register in DApp Store" unless app

    # User has not granted his account access to this application, "Visit store.mobius.wallet and allow"
    return render plain: "Visit https://store.mobius.network/flappy_bird" unless app.authorized?
  end

  # GET /balance
  def balance
    render plain: app.balance
  end

  # POST /pay
  def pay
    app.pay(ROUND_PRICE)
    render plain: app.balance
  rescue Mobius::Client::Error::InsufficientFunds
    render :gone
  end

  private

  def token_s
    session[:token] = params[:token] || session[:token]
  end

  def token
    @token ||= Mobius::Client::Auth::Jwt.new(Rails.application.secrets.app[:jwt_secret]).decode!(token_s)
  rescue Mobius::Client::Error
    nil # We treat all invalid tokens as missing
  end

  def app
    @app ||= token && Mobius::Client::App.new(
      Rails.application.secrets.app[:secret_key], # SA2VTRSZPZ5FIC.....I4QD7LBWUUIK
      token.public_key                            # Current user
    )
  end
end
```

Check example:

    $ git clone git@github.com/mobius-network/mobius-client-ruby.git
    $ cd mobius-client-ruby && bundle
    $ cd examples/app && bundle && ruby app.rb

### CLI Test Implementation

  Normally, Mobius Wallet will request challenge, validate it, obtain access token and pass it to the application. For development purposes you have two options: use `mobius-cli` or make your own script.

  ```
  # Will fetch token from working application
  $ mobius-cli auth fetch -j secret \
    http://localhost:4567/auth SA2VTRSZPZ5FIC.....I4QD7LBWUUIK GCWYXW7RXJ5.....SV4AK32ECXFJ

  # Will fetch calculate everything locally
  $ mobius-cli auth token -j secret \
    SA2VTRSZPZ5FIC.....I4QD7LBWUUIK SGZKDAKASDSD.....I4QD7LBWUUIK
  ```

  Use `-j` if you want to return JWT token, otherwise transaction hash will be returned.

  Check `lib/mobius/cli/auth.rb` for details.

# TODO

1. spec & doc App.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mobius-network/mobius-client-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Mobius::Client project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/mobius-client/blob/master/CODE_OF_CONDUCT.md).
