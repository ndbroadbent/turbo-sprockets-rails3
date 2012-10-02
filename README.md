# Turbo Sprockets for Rails 3.2.x

[![Build Status](https://secure.travis-ci.org/ndbroadbent/turbo-sprockets-rails3.png)](http://travis-ci.org/ndbroadbent/turbo-sprockets-rails3)

* Speeds up the Rails 3 asset pipeline by only recompiling changed assets, based on a hash of their source files
* Generates both non-fingerprinted and fingerprinted assets from a single compile

This is a backport of the work I've done for Rails 4.0.0, released as
a gem for Rails 3.2.x. (See [sprockets-rails #21](https://github.com/rails/sprockets-rails/pull/21) and [sprockets #367](https://github.com/sstephenson/sprockets/pull/367) for the Rails 4 pull requests.)


### Disclaimer

Please test this out thoroughly on your local machine before deploying to a production site, and open an issue on GitHub if you have any problems. By using this software you agree to the terms and conditions in the [MIT license](https://github.com/ndbroadbent/turbo-sprockets-rails3/blob/master/MIT-LICENSE).

## Supported Versions

### Ruby

All versions of Ruby that are supported by Rails `3.2.x`, including `1.9.3`, `1.9.2`, `1.8.7` and REE.

### Rails

This gem only supports Rails `3.2.0` or higher.
Rails `3.1.x` support is not available at this time, because it depends on an outdated version of `sprockets`.

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
precompile time in half, since it only needs to compile assets once.

If you want to make the most of `turbo-sprockets-rails3`, you can run `assets:precompile` on your local machine and commit the compiled assets. When you push compiled assets to Heroku, it will automatically skip the `assets:precompile` task.

I've automated this process in a Rake task for my own projects. My task creates a deployment repo at `tmp/heroku_deploy` so that you can keep working while deploying, and it also rebases and amends the assets commit to keep your repo's history from growing out of control. You can find the deploy task in a gist at https://gist.github.com/3802355. Save this file to `lib/tasks/deploy.rake`, make sure you have added a `heroku` remote to your repo, and you will now be able to run `rake deploy` to deploy your app to Heroku.

## Debugging

If you would like to view debugging information in your terminal during the `assets:precompile` task, add the following lines to the bottom of `config/environments/production.rb`:

```ruby
config.log_level = :debug
config.logger = Logger.new(STDOUT)
```
