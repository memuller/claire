require 'spec/runner/formatter/progress_bar_formatter'
class CustomFormatter < Spec::Runner::Formatter::ProgressBarFormatter
  def add_line(l)
    (@lines||=[]) << l
  end

  def dump_pending
    unless @pending_examples.empty?
      lpad = @pending_examples.map{|e|e[2].length}.max
      @output.puts
      @output.puts "Pending: #{@pending_examples.length}"
      @pending_examples.each do |pending_example|
        @output.puts yellow("#{pending_example[2].strip.ljust(lpad)}  # - #{pending_example[1]}")
      end
    end
    @output.flush
  end

#  def example_failed(example, counter, failure)
#    failure.instance_eval do
#      (class<<self;self;end).class_eval { attr_accessor :location }
#    end
#    failure.location = example.location
#    super(example,counter,failure)
#  end

  def dump_summary(duration, example_count, failure_count, pending_count)
    if @lines
      @output.puts "="*72
      @lines.each do |line|
        @output.puts line
      end
      @output.puts "="*72
    end
    super(duration, example_count, failure_count, pending_count)
  end

  def dump_failure(counter, failure)
    @output.puts
    @output.puts "#{counter.to_s})"
    # @output.puts failure.location
    @output.puts colorize_failure("#{failure.header}\n#{failure.exception.message}", failure.inspect)
    @output.puts format_backtrace(failure.exception.backtrace)
    #failure.exception
    line = failure.exception.backtrace.last rescue failure.exception.inspect
    add_line line
    @output.flush
  end
end
