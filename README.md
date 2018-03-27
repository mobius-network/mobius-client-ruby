# Mobius::Client

Mobius DApp Store API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mobius-client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mobius-client

## Developing an application

- DApp Store applications are making payments using Stellar network.
- Every Application holds private key of account receiving money from users.
- Every user holds private key of account containing MOBI specific application can use.
- Permission to use user's money is granted to application via adding it's public key as cosigner to user's account.

### Setting up an application account

Run:

```
mobius-cli create app
```

This will create application account, MOBI trust line and fund this account with 1000 MOBI on Stellar test network.

Otherwise, you could use https://mobius.network/friendbot

## Authentication

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

```
cd examples/auth && bundle && ruby auth.rb
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mobius-network/mobius-client. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Mobius::Client project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/mobius-client/blob/master/CODE_OF_CONDUCT.md).
