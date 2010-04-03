require 'logger'
module StateFu
  #
  # TODO - spec coverage
  #
  # Provide logging facilities, including the ability to use a shared logger.  
  # Use Rails' log if running as a rails plugin; allow independent control of 
  # StateFu log level.
  
  class Logging
    cattr_accessor :prefix   # prefix for log messages
    cattr_accessor :suppress # set true to send messages to /dev/null
    cattr_accessor :shared
    cattr_accessor :suppress
    
    DEBUG   = 0
    INFO    = 1
    WARN    = 2
    ERROR   = 3
    FATAL   = 4
    UNKNOWN = 5

    ENV_LOG_LEVEL = 'STATEFU_LOGLEVEL'
    DEFAULT_LEVEL = INFO

    DEFAULT_SHARED_LOG_PREFIX = '[StateFu] '

    @@prefix    = DEFAULT_SHARED_LOG_PREFIX
    @@logger    = nil
    @@suppress  = false
    @@shared    = false
    @@log_level = nil

    def self.new( logger=nil, options={} )
      @@suppress = false
      set_logger(logger, options)
      self
    end

    def self.initial_log_level
      if env_level = ENV[ENV_LOG_LEVEL]
        parse_log_level( env_level )
      else
        DEFAULT_LEVEL
      end
    end

    def self.level
      @@log_level ||= initial_log_level
    end

    def self.level=( new_level )
      @@log_level = parse_log_level(new_level)
    end

    def self.shared?
      !!@@shared
    end

    def self.prefix
      shared? ? @@prefix : nil
    end

    def self.logger= new_logger
      set_logger new_logger
    end

    def self.instance
      @@logger ||= default_logger
    end

    def self.suppress!
      self.suppress = true
    end

    def self.suppressed?(severity = DEBUG)
      suppress == true || severity < level
    end

    def self.add(severity, message = nil, progname = nil, &block)
      severity = parse_log_level( severity )
      return if suppressed?( severity )
      message = [prefix, (message || (block && block.call) || progname).to_s].compact.join
      # message = "#{message}\n" unless message[-1] == ?\n
      instance.add( severity, message )
    end

    def self.debug   progname = nil, &block; add DEBUG,   progname, &block; end
    def self.info    progname = nil, &block; add INFO,    progname, &block; end 
    def self.warn    progname = nil, &block; add WARN,    progname, &block; end 
    def self.error   progname = nil, &block; add ERROR,   progname, &block; end 
    def self.fatal   progname = nil, &block; add FATAL,   progname, &block; end 
    def self.unknown progname = nil, &block; add UNKNOWN, progname, &block; end 

    #
    # TODO fix these crappy methods
    #
    
    # setter for logger instance
    def self.set_logger( logger, options = { :shared => false } )
      case logger
      when String
        file     = File.open(logger, File::WRONLY | File::APPEND)        
        @@logger = activesupport_logger_available? ? ActiveSupport::BufferedLogger.new(file) : Logger.new(file)
      when Logger
        @@logger = logger
      when activesupport_logger_available? && ActiveSupport::BufferedLogger
        @@logger = logger
      else
        default_logger
      end
      self.shared = !!options.symbolize_keys![:shared]
      if shared?
        @@prefix = options[:prefix] || DEFAULT_SHARED_LOG_PREFIX
        puts "shared :: #{@@prefix} #{prefix}"
      end      
      if lvl = options[:level] || options[:log_level]
        self.level = lvl
      end      
      instance
    end

    private
    
    def self.activesupport_logger_available?
      Object.const_defined?( 'ActiveSupport' ) && ActiveSupport.const_defined?('BufferedLogger')
    end
    
    def self.default_logger(target=$stdout)
      if activesupport_logger_available?
        if Object.const_defined?("RAILS_DEFAULT_LOGGER")
          RAILS_DEFAULT_LOGGER
        else
          ActiveSupport::BufferedLogger.new(target)
        end
      else      
        Logger.new(target)
      end
    end
    
    def self.parse_log_level(input)
      case input
      when String, Symbol
        const_get( input )
      when 0,1,2,3,4,5
        input
      when nil
        level
      else
        raise ArgumentError.new(input.inspect)
      end
    end
    
  end
end

