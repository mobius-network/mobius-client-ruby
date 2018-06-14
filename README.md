[![Gem Version](https://badge.fury.io/rb/mobius-client.svg)](https://badge.fury.io/rb/mobius-client)
[![Build Status](https://travis-ci.org/mobius-network/mobius-client-ruby.svg?branch=master)](https://travis-ci.org/mobius-network/mobius-client-ruby)
[![Maintainability](https://api.codeclimate.com/v1/badges/a99a88d28ad37a79dbf6/maintainability)](https://codeclimate.com/github/codeclimate/codeclimate/maintainability)

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

    $ mobius-cli create dapp-account

Creates a new Stellar account with 1,000 test-net MOBI.

You can also obtain free test network MOBI from https://mobius.network/friendbot

### Setting up test user accounts

1. Create empty Stellar account without a MOBI trustline.
    ```
      $ mobius-cli create account
    ```
2. Create stellar account with 1,000 test-net MOBI
    ```
      $ mobius-cli create dapp-account
    ```
3. Create stellar account with 1,000 test-net MOBI and the specified application public key added as a signer
    ```
      $ mobius-cli create dapp-account -a <Your application public key>
    ```

### Account Creation Wizard

Below command will create and setup the 4 account types above for testing and generate a simple HTML test interface that simulates the DApp Store authentication functionality (obtaining a challenge request from an app, signing it, and then openining the specified app passing in a JWT encoded token the application will use to verify this request is from the user that owns the specified MOBI account).

```
  $ mobius-cli create dev-wallet
```

## Authentication

### Explanation

When a user opens an app through the DApp Store it tells the app what Mobius account it should use for payment.

The application needs to ensure that the user actually owns the secret key to the Mobius account and that this isn't a replay attack from a user who captured a previous request and is replaying it.

This authentication is accomplished through the following process:

* When the user opens an app in the DApp Store it requests a challenge from the application.
* The challenge is a payment transaction of 1 XLM from and to the application account. It is never sent to the network - it is just used for authentication.
* The application generates the challenge transaction on request, signs it with itss own private key, and sends it to user.
* User receives the challenge transaction, verifies it is signed by the application's secret key by checking it the application's published public key that it receives through the DApp Store, and then signs the transaction which its own private key and sends it back to application along with its public key.
* Application checks that challenge transaction is now signed by itself and the public key that was passed in. Time bounds are also checked to make sure this isn't a replay attack. If everything passes the server replies with a token the application can pass in to "login" with the specified public key and use it for payment (it would have previously given the app access to the public key by adding the app's public key as a signer).

Note: the challenge transaction also has time bounds to restrict the time window when it can be used.

See demo at:

    $ git clone git@github.com/mobius-network/mobius-client-ruby.git
    $ cd mobius-client-ruby && bundle
    $ cd examples/auth && bundle && ruby auth.rb

### Sample Server Implementation

```
class AuthController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:authenticate]

  # GET /auth
  # Generates and returns challenge transaction XDR signed by application to user
  def challenge
    render plain: Mobius::Client::Auth::Challenge.call(
      Rails.application.secrets.app[:secret_key], # SA2VTRSZPZ5FIC.....I4QD7LBWUUIK
      12.hours                                    # Session duration
    )
  end

  # POST /auth
  # Validates challenge transaction. It must be:
  #   - Signed by application and requesting user.
  #   - Not older than 10 seconds from now (see Mobius::Client.strict_interval`)
  def authenticate
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
```

## Payment

### Explanation

After the user completes the authentication process they have a token T. They now pass it to the application to "login" which tells the application which Mobius account to withdraw MOBI from (the user public key) when a payment is needed. For a web application the token is generally passed in via a `token` request parameter. Upon opening the website/loading the application it checks that the token is valid (within time bounds etc) and the account in the token has added the app as a signer so it can withraw MOBI from it.


See demo at:

    $ git clone git@github.com/mobius-network/mobius-client-ruby.git
    $ cd mobius-client-ruby && bundle
    $ cd examples/app && bundle && ruby app.rb

### Sample Server Implementation

```
class AppController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:pay]

  ROUND_PRICE = 5

  # GET /
  # User opens the application passing in the token variable.
  def index
    # User has opened application page without a token
    return render plain: "Visit https://store.mobius.network to register in the DApp Store" unless app

    # User has not granted access to his MOBI account so we can't use it for payments
    return render plain: "Visit https://store.mobius.network and open our app" unless app.authorized?

    # token is valid - should render the application or redirect to the main application page etc
  end

  # GET /balance
  def balance
    render plain: app.balance
  end

  # POST /charge
  def charge
    app.charge(ROUND_PRICE)
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

## Sample Application

[Flappy Bird](https://github.com/mobius-network/flappy-bird-dapp) has been reimplemented using this new arhictecture and the above simple server code!

## CLI Test Implementation

  Normally, as mentioned the Mobius DApp Store will request a challenge, validate and sign it, pass it back to the application to obtain an access token, and then open the application and pass in the token.

  For development purposes you can use the simple HTML test interface generated via `mobius-cli create dev-wallet` as mentioned above in the "Account Creation Wizard" section or you can use the these CLI commands.

```
  # Fetch token from working application
  # mobius-cli auth fetch <URL> <User secret> <App public>
  $ mobius-cli auth fetch -j secret \
    http://localhost:4567/auth SA2VTRSZPZ5FIC.....I4QD7LBWUUIK GCWYXW7RXJ5.....SV4AK32ECXFJ

  # Generate token locally using the provided app secret
  # mobius-cli auth token <User secret> <App secret>
  $ mobius-cli auth token -j secret \
    SA2VTRSZPZ5FIC.....I4QD7LBWUUIK SGZKDAKASDSD.....I4QD7LBWUUIK
```

  Use `-j` if you want to return JWT token, otherwise transaction hash will be returned.

  Check `lib/mobius/cli/auth.rb` for details.

## Documentation

[[RDoc.info](http://www.rubydoc.info/github/mobius-network/mobius-client-ruby/master)]

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mobius-network/mobius-client-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Mobius::Client project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/mobius-client/blob/master/CODE_OF_CONDUCT.md).
