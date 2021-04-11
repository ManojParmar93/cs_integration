# README
## Prerequisites

Before starting, you need to have these things installed:

* Git
* Homebrew for mac user
* Ruby rbenv

## Installation

1. Pull repo
2. Run `bundle install`
3. Run `bundle exec rake db:reset`
4. Use `.env.sample` content as your base `.env` file.
5. Run Start server:`rails server` and `bundle exec sidekiq`
6. Run Test-cases: `bundle exec rspec spec` and check test-cases coverage with `open index.html`


Go to http://localhost:3000 and you'll see: "Yay! You’re on Rails!"

![](http://i.giphy.com/vtVpHbnPi9TLa.gif)
