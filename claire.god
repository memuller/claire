#==this little guy keeps the whole system running

module God
	module Conditions
		class WorklingHanged < PollCondition
			def initialize; super; end 
			def valid?; true; end
			def test
				file = %x[tail -1 #{God.pid_file_directory}/workling.output]
				if file.include? "Exiting" or file.include? "from script/workling_client"
					true
				else
					false
				end 
			rescue
				true
			end
		end
	end
end
WANTS = %w(mongo starling workling mongrel)
RAILS_ENV = 'production'
RAILS_ROOT = File.dirname __FILE__
RAILS_USER = "memuller"
RAILS_GROUP = "staff"
RUBY_BIN = "ruby"
God.pid_file_directory = "#{RAILS_ROOT}/log"

#== STARLING MESSAGE SERVER
if WANTS.include? 'starling'
	God.watch do |t|
	  t.name = "starling"
	  t.start = "starling -p 22122"
	  t.start_grace = 10.seconds
	  t.interval = 20.seconds
	  t.start_if do |start|
	    start.condition :process_running do |p|
	      p.interval = 20.seconds
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
	      c.above = 80.percent
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
end

#== WORKLING MESSAGE CLIENT
if WANTS.include? 'starling'
	God.watch do |t|
	  t.name = "workling"
	  t.dir = RAILS_ROOT
	  #t.gid = RAILS_GROUP
	  #t.uid = RAILS_USER #needs to run as such to ensure local gems are okay
		# ops, user gems aren't working. Oh well, we need to run those as root anyway, so whatever
	  t.start = "RAILS_ENV=#{RAILS_ENV} #{RUBY_BIN} script/workling_client start"
	  t.stop = "RAILS_ENV=#{RAILS_ENV} #{RUBY_BIN} script/workling_client stop"
	  t.stop = "RAILS_ENV=#{RAILS_ENV} #{RUBY_BIN} script/workling_client restart"
	  t.interval = 15.seconds
	  t.start_grace = 5.seconds
	  t.restart_grace = 5.seconds
  
  
	  #runs as a daemon, so requires an way to track status via PID
	  t.pid_file = File.join(God.pid_file_directory, "workling_monitor.pid")
	  t.behavior(:clean_pid_file)
  
		t.restart_if do |restart|
			restart.condition :workling_hanged do |p|
				p.interval = 15.seconds
			end
	  end

	  t.start_if do |start|
	    start.condition :process_running do |p|
	      p.interval = 40.seconds
	      p.running = false
	    end
		end
	end	         
end

#== MONGOD
if WANTS.include? 'starling'
# presumes an mongod aliased or properly configured command, or will fail
# TODO: make a local config file and data store
	God.watch do |t|
	  t.name = "mongod"
	  t.start = "mongod"
	  t.start_grace = 10.seconds
  
	  t.start_if do |start|
	    start.condition :process_running do |p|
	      p.interval = 30.seconds
	      p.running = false
	    end    
	  end
	end
end

#== MONGREL
# starts up an daemonized mongrel instance
if WANTS.include? 'starling'
	God.watch do |t|
		t.name = "mongrel"
		t.dir = RAILS_ROOT
		t.start = "mongrel_rails start -c #{RAILS_ROOT} -P #{RAILS_ROOT}/log/mongrel.pid -p 3000 -d"
		t.restart = "mongrel_rails restart -c #{RAILS_ROOT} -P #{RAILS_ROOT}/log/mongrel.pid"
		t.stop = "mongrel_rails start -c #{RAILS_ROOT} -P #{RAILS_ROOT}/log/mongrel.pid -w 5"
		t.start_grace = 30.seconds
		t.pid_file = File.join(God.pid_file_directory, "mongrel.pid")
	  t.behavior(:clean_pid_file)
	
		t.start_if do |start|
	    start.condition :process_running do |p|
	      p.interval = 20.seconds
	      p.running = false
	    end    
	  end
	end
end