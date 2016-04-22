namespace :consul_kv_lock do
  def latch
    Capistrano::ConsulKvLock::Latch.instance || \
      Capistrano::ConsulKvLock::Latch.set_instance(fetch(:consul_url), consul_lock_key: fetch(:consul_lock_key))
  end

  task :check_lock do
    if latch.locked?
      fail("Deployment is locked!")
    end
  end

  task :start_session do
    latch.create_session
  end

  task :destroy_session do
    latch.delete_session
  end

  task :lock do
    run_locally do
      info("Setting lock to #{fetch(:consul_url)}")
      unless latch.lock
        warn("Setting lock to #{fetch(:consul_url)} failed! Skipping.")
      end
    end
  end

  task :unlock do
    run_locally do
      info("Deleting lock from #{fetch(:consul_url)}")
      unless latch.unlock
        warn("Deleting lock from #{fetch(:consul_url)} failed! Skipping.")
      end
    end
  end
end

before 'deploy:starting', 'consul_kv_lock:lock'
before 'consul_kv_lock:lock', 'consul_kv_lock:start_session'
before 'consul_kv_lock:start_session', 'consul_kv_lock:check_lock'

after  'deploy:finished', 'consul_kv_lock:unlock'
after  'deploy:failed', 'consul_kv_lock:unlock'
after  'consul_kv_lock:unlock', 'consul_kv_lock:destroy_session'

namespace :load do
  task :defaults do

    set :consul_url,      -> { 'http://localhost:8500' }
    set :consul_lock_key, -> { 'deployment/locked' }

  end
end
