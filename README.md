# Turbo Sprockets for Rails 3.2.x

[![Build Status](https://secure.travis-ci.org/ndbroadbent/turbo-sprockets-rails3.png)](http://travis-ci.org/ndbroadbent/turbo-sprockets-rails3)

* Speeds up your Rails 3 `rake assets:precompile` by only recompiling changed assets, based on a hash of their source files
* Only compiles once to generate both fingerprinted and non-fingerprinted assets


### Disclaimer

`turbo-sprockets-rails3` can now be considered relatively stable. A lot of compatibility issues and bugs have been solved, so you shouldn't run into any problems.
However, please do test it out on your local machine before deploying to a production site, and open an issue on GitHub if you have any problems. By using this software you agree to the terms and conditions in the [MIT license](https://github.com/ndbroadbent/turbo-sprockets-rails3/blob/master/MIT-LICENSE).

## Supported Versions

### Ruby

All versions of Ruby that are supported by Rails `3.2.x`, including `1.9.3`, `1.9.2`, `1.8.7` and REE.

### Rails

This gem only supports Rails `3.2.0` or higher.

## Usage

Just drop the gem in your `Gemfile`, under the `:assets` group:

```ruby
group :assets do
  ...
  gem 'turbo-sprockets-rails3'
end
```

Run `bundle` to install the gem, and you're done!

Test it out by running `rake assets:precompile`. When it's finished, you should see a new file at `public/assets/sources_manifest.yml`, which includes the source fingerprints for your assets.

Go on, run `rake assets:precompile` again, and it should be a whole lot faster than before.

Enjoy your lightning fast deploys!

## Removing Expired Assets

`turbo-sprockets-rails3` can now remove expired assets after each compile. If the environment variable `CLEAN_EXPIRED_ASSETS` is set to `true`, the `assets:clean_expired` task will be run after `assets:precompile`.
An asset will be deleted if it is no longer referenced by `manifest.yml`, and is older than 7 days (by default).

To expire old assets after precompile, you should compile assets by running `CLEAN_EXPIRED_ASSETS=true rake assets:precompile`. Alternatively, you could run `rake assets:precompile assets:clean_expired`.

You can configure the expiry time by setting `config.assets.expire_after` in `config/environments/production.rb`.
An expiry time of 2 weeks could be configured with the following code:

```ruby
config.assets.expire_after 2.weeks
```

## Compatibility

### [asset_sync](https://github.com/rumblelabs/asset_sync)

Fully compatible.

### [wicked_pdf](https://github.com/mileszs/wicked_pdf)

Fully compatible. However, you will need to use the latest code on the `wicked_pdf` master branch until a version newer than `0.7.9` is released. Add the following line to your `Gemfile`:

```ruby
gem 'wicked_pdf', :github => "mileszs/wicked_pdf"
```

<hr/>

Please let me know if you have any problems with other gems, and I will either fix it, or make a note of the problem here.

## Deployments

### Capistrano

`turbo-sprockets-rails3` should work out of the box with Capistrano.

You may also like to take a look at my [Capistrano Pull Request](https://github.com/capistrano/capistrano/pull/281) that attempts to solve the problems of asset rollback and invalidation. You can try out this solution by adding the following to your Gemfile:

```ruby
gem "capistrano", :github => "ndbroadbent/capistrano", :branch => "assets_rollback_and_expiry"
```

### Heroku

I have created a Heroku Buildpack for `turbo-sprockets-rails3` that keeps your assets cached between deploys, so you only need to recompile changed assets. It will automatically expire old assets that are no longer referenced by `manifest.yml` after 7 days, so your `public/assets` folder won't grow out of control.

To create a new application on Heroku using this buildpack, you can run:

```bash
heroku create --buildpack https://github.com/ndbroadbent/heroku-buildpack-turbo-sprockets.git
```

To add the buildpack to an existing app, you can run:

```bash
heroku config:add BUILDPACK_URL=https://github.com/ndbroadbent/heroku-buildpack-turbo-sprockets.git
```

#### Compiling Assets on Your Local Machine

You can also compile assets on your local machine, and commit the compiled assets. You might want to do this if your local machine is a lot faster than the Heroku VM, or if you also want to generate other files, such as static pages. When you push compiled assets to Heroku, it will automatically skip the `assets:precompile` task.

I've automated this process in a Rake task for my own projects. The task creates a deployment repo at `tmp/heroku_deploy` so that you can keep working while deploying, and it also rebases and amends the assets commit to keep your repo's history from growing out of control. You can find the deploy task in a gist at https://gist.github.com/3802355. Save this file to `lib/tasks/deploy.rake`, and make sure you have added a `heroku` remote to your repo. You will now be able to run `rake deploy` to deploy your app to Heroku.

## Debugging

If you would like to view debugging information in your terminal during the `assets:precompile` task, add the following lines to the bottom of `config/environments/production.rb`:

```ruby
config.log_level = :debug
config.logger = Logger.new(STDOUT)
```
