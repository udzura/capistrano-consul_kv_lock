# Capistrano::ConsulKvLock

Introduces deployment lock using consul KVS

## Detail

Using this plugin, capistrano just puts consul KVS a lock value,
then the deployment is prohibitted in another host
for the lock value is released.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'capistrano-consul_kv_lock'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano-consul_kv_lock

Activate in `Capfile`:

```ruby
require 'capistrano/consul_kv_lock'
```

## Usage

### Settings

```ruby
# Consul API URL that the operator uses as KVS.
set :consul_url,      -> { 'http://localhost:8500' }

# A key name for locking deploy.
set :consul_lock_key, -> { 'deployment/locked' }
```

### Force unlock

Delete the KVS lock value.

```
$ curl -X DELETE ${your_consul_host}:8500/v1/kv/deployment/locked
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/capistrano-consul_kv_lock/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
