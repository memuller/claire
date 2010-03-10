class Symbol
	def to_class
		self.to_s.classify.constantize rescue return nil
	end
end
class	Hash
	def keys_to_sym
		result = {}
		self.each do |k,v|
			k = k.to_sym if k.respond_to? :to_sym 
			result.merge!({k => v}) 
		end
		result
	end
end

module Kernel
	def retryable(args = {}, &block)
	  options = { :tries => 1, :on => Exception }.merge args
	  retry_exception, retries = args[:on], args[:tries]

	  begin
	    return yield
	  rescue 
	    retry if (retries -= 1) > 0
	  end
	  yield
	end	
end

class WorkerLogger
	def ok args
		puts "OK: " + args.to_s + "."
	end
	def error args
		puts "ERROR: " + args.to_s + ""
	end
	def start args
		puts "START: " + args.to_s + "..."
	end
end
LOGGER = WorkerLogger.new