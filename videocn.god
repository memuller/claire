# run with: god -c /path/to/mongrel.god -D
# 
# This is the actual config file used to keep the mongrels of
# gravatar.com running.

RAILS_ROOT = File.dirname __FILE__
RAILS_USER = "memuller"
God.pid_file_directory = "#{RAILS_ROOT}/log"

#== STARLING MESSAGE SERVER
God.watch do |t|
  t.name = "starling"
  t.start = "starling -p 22122"
  t.start_grace = 10.seconds
  t.interval = 20.seconds
  t.start_if do |start|
    start.condition :process_running do |p|
      p.interval = 10.seconds
      p.running = false
    end
  end
  
  #restarts on memory > 60mb, cpu > 50%
  t.restart_if do |restart|
    restart.condition :memory_usage do |m|
      m.above = 60.megabytes
      m.times = [1,5]
    end    
    restart.condition :cpu_usage do |c|
      c.above = 50.percent
      c.times = 3
    end
  end
  
  #borderline conditions
  t.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 2
      c.within = 2.minutes
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
    end
  end
      
end

#== WORKLING MESSAGE CLIENT
God.watch do |t|
  t.name = "workling"
  t.dir = RAILS_ROOT
  t.start = "ruby script/workling_client start"
  t.stop = "ruby script/workling_client stop"
  t.stop = "ruby script/workling_client restart"
  t.interval = 30.seconds
  t.start_grace = 10.seconds
  t.restart_grace = 10.seconds
  t.uid = RAILS_USER #needs to run as such to ensure local gems are okay
  
  #runs as a daemon, so requires an way to track status via PID
  t.pid_file = File.join(God.pid_file_directory, "workling.pid")
  t.behavior(:clean_pid_file)
  
  t.start_if do |start|
    start.condition :process_running do |p|
      p.interval = 10.seconds
      p.running = false
    end
  end  
end

#== MONGOD
# presumes an mongod aliased or properly configured command, or will fail
# TODO: make a local config file and data store
God.watch do |t|
  t.name = "mongod"
  t.start = "mongod"
  t.start_grace = 10.seconds
  
  t.start_if do |start|
    start.condition :process_running do |p|
      p.interval = 10.seconds
      p.running = false
    end    
  end
end