# Turbo Sprockets for Rails 3

* Speeds up the Rails 3 asset pipeline by only recompiling changed assets
* Generates non-digest assets from precompiled assets - Only compile once!

This is a backport of the work I've done for Rails 4.0.0, released as
a gem for Rails 3.2.x. (See [sprockets-rails #21](https://github.com/rails/sprockets-rails/pull/21) and [sprockets #367](https://github.com/sstephenson/sprockets/pull/367) for the Rails 4 pull requests.)


### Disclaimer

Please test this out thoroughly on your local machine before deploying to a production site, and open an issue on GitHub if you have any problems. By using this software you agree to the terms and conditions in the [MIT license](https://github.com/ndbroadbent/turbo-sprockets-rails3/blob/master/MIT-LICENSE).

## Dependencies

* sprockets `~> 2.1.3`
* railties `~> 3.2.0`

## Usage

Just drop the gem in your `Gemfile`:

```ruby
gem 'turbo-sprockets-rails3'
```

Run `bundle`, and you're done!


Test it out by running `rake assets:precompile`. When it's finished, your `public/assets/manifest.yml` file should include a `:source_digests` hash for your assets.

Go on, run `rake assets:precompile` again, and it should be a whole lot faster than before.

Enjoy your lightning fast deploys!

## Deployments

### Capistrano

`turbo-sprockets-rails3` should work out of the box with Capistrano.

### Heroku

You won't be able to do an 'incremental update' on heroku, since your `public/assets`
folder will be empty at the start of each push. However, this gem can still cut your
precompile time in half, since it only compiles assets once to generate both digest and non-digest assets.

## Debugging

If you would like to view debugging information in your terminal during the `assets:precompile` task, add the following lines to the bottom of `config/environments/production.rb`:

```ruby
config.log_level = :debug
config.logger = Logger.new(STDOUT)
```
