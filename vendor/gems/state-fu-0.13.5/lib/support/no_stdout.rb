require 'stringio'

# a module for suppressing or capturing STDOUT or STDERR.
# useful when shelling out to "noisy" applications or to suppress
# output during tests.
module NoStdout  #:nodoc:all
  module InstanceMethods

    # Suppresses or redirects STDOUT inside the given block.
    # supply an IO of your own to capture STDOUT, otherwise it's put
    # in a new StringIO object.
    def no_stdout ( to = StringIO.new('','r+'), &block )
      orig_stdout  = $stdout
      $stdout      = @alt_stdout = to
      result       = yield
      $stdout      = orig_stdout
      result
    end

    # returns the contents of STDOUT from the previous usage of
    # no_stdout, or nil
    def last_stdout
      return nil unless @alt_stdout
      @alt_stdout.rewind
      @alt_stdout.read
    end

    ## COPIED FROM ABOVE ####

    # Suppresses or redirects STDERR inside the given block.
    # supply an IO of your own to capture STDERR, otherwise it's put
    # in a new StringIO object.
    def no_stderr ( to = StringIO.new('','r+'), &block )
      orig_stderr  = $stderr
      $stderr      = @alt_stderr = to
      result       = yield
      $stderr      = orig_stderr
      result
    end

    # returns the contents of STDERR from the previous usage of
    # no_stderr, or nil
    def last_stderr
      return nil unless @alt_stderr
      @alt_stderr.rewind
      @alt_stderr.read
    end
  end

  def self.included klass
    klass.class_eval do
      include InstanceMethods
    end
  end
end
