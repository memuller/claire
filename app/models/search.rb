class Search
	attr_accessor :params, :result, :range
	
	def build_range
		@range = @result.empty? ? @result.map!{ |item| item.id } : []		
	end
  
  def params_without_options
		params = {}
		params.replace(@params).delete_if{ |k,v| [:offset, :limit, :okay].include?(k) }
		params
	end
	
	def add_options args, specify = false
		if @i == 0 or specify == :begin
			args.merge!(:okay => @params[:okay]) if @klass == Video
		end 
		if (@i >= (params_without_options.size - 1)) or specify == :end
			args.merge!(:offset => @params[:offset]) if @params[:offset]
			args.merge!(:limit => @params[:limit]) if @params[:limit]			
		end
		args
	end
	
	def add_range args
		build_range
		args.merge!({ :id => {'$in' => [*@range]} }) unless @range.empty?
		puts "range was #{@range}"
		args
	end

	def search
		@i = 0 and @result = [] and @range = []
		params_without_options.each do |attribute, value|
			if value.is_a? Array
				value.each_with_index do |item,j|
					params = {attribute => item} and params = add_range(params)
					params = add_options(params) if j == 0 or j >= value.size - 1
					@result = @klass.all params					
				end
			else
			 	
				params = {attribute => value}
								
				params = add_range(params)
				puts params.to_s
				params = add_options(params)
				puts params.to_s
				@result = @klass.all params
			end
			@i += 1				
		end
		return @result 
	end
	
	# sorts params fields according to the order that they should appear in a query.
	def sort_fields
		@params.each do |k,v|
			@sorting_weight.merge!({k => 5}) unless @sorting_weight.has_key? k
		end			
		
	  @sorting_weight = {
			:offset => 10,
			:limit => 10,
			:okay => -1,
			:category_name => 1,
			:subcategory_name => 2,
			:tags => 3,
			:text => 4			   
		}
		params_arr = @params.sort{ |a,b| sorting_weight[a[0]] <=> sorting_weight[b[0]] }
		@params = OrderedHash.new
		params_arr.each do |item|
			@params.merge! [item].to_h
		end		
	end
	
	def initialize params={}
		@params = params		
		@params[:what] ||= :videos
		@klass = @params[:what].to_s.classify.constantize
		@params.delete :what
		@params[:okay] ||= true if @klass = Video
			
		search
		@result
	end
	
	
	
end