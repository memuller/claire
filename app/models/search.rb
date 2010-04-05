class Search
	attr_accessor :params, :results, :range
	
	def build_range
		@range = @results.empty? ? @results.map!{ |item| item.id } : []		
	end
  
  def params_without_options
		params = {}
		params.replace(@params).delete_if{ |k,v| [:offset, :limit, :okay, :order].include?(k) }
		params
	end
	
	def add_options args, specify = false
		if @i == 0 or specify == :begin
			args.merge!(:okay => @params[:okay]) if @klass == Video
		end 
		if (@i >= (params_without_options.size - 1)) or specify == :end
			args.merge!(:offset => @params[:offset]) if @params[:offset]
			args.merge!(:limit => @params[:limit]) if @params[:limit]
			args.merge!(:order => @params[:order]) if @params[:order]			
		end
		args
	end
	
	def add_range args
		build_range
		args.merge!({ :id => {'$in' => [*@range]} }) unless @range.empty?
		args
	end

	def search
		@i = 0 and @results = [] and @range = []
		if params_without_options.empty?
			@results = @klass.all @params
			return @results
		end
		params_without_options.each do |attribute, value|
			if value.is_a? Array
				value.each_with_index do |item,j|
					params = {attribute => item} and params = add_range(params)
					params = add_options(params) if j == 0 or j >= value.size - 1
					@results = @klass.all params					
				end
			else
			 	value = /#{value}/i if attribute == :texts
				params = {attribute => value}				
				params = add_range(params)
				#puts params.to_yaml
				params = add_options(params)
				#puts params.to_yaml
				@results = @klass.all params
			end
			@i += 1				
		end
		return @results 
	end
	
	# sorts params fields according to the order that they should appear in a query.
	def sort_fields
		@params.each do |k,v|
			@sorting_weight.merge!({k => 5}) unless @sorting_weight.has_key? k
		end			
		
	  @sorting_weight = {
			:order => 10,
			:offset => 10,
			:limit => 10,
			:owner_id => -2,
			:okay => -1,
			:category_name => 1,
			:subcategory_name => 2,
			:tags => 3,
			:texts => 4			   
		}
		params_arr = @params.sort{ |a,b| sorting_weight[a[0]] <=> sorting_weight[b[0]] }
		@params = OrderedHash.new
		params_arr.each do |item|
			@params.merge! [item].to_h
		end		
	end
	
	def initialize params={}
		@params = {}                         
		params[:limit] = CONFIG['general']['per_page'] if params[:limit].nil?
		if params[:page]
			params[:offset] = ( (params[:page] - 1) * params[:limit] ) - 1
		end 
		params.delete_if{|k,v| %w(format action controller page).include? k}		
		params.each do |k,v|
			v = case v
			when 'true'
				true
			when 'false'
				false
			else
				v
			end
			@params.merge!({k.to_sym => v})
		end
		@params[:what] = :videos unless @params[:what]
		@klass = @params[:what].to_s.classify.constantize
		@params.delete :what
		@params[:okay] = true if @klass = Video and @params[:okay].nil?	
		search
		return @results
	end
	
	
	
end