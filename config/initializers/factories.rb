SAMPLE_STREAMS = [["TVCN", "http://wmsint.webtvcn.com/tvonline"],
	["TVCN Portugal", "http://wmsint.webtvcn.com/tvcnportugal"],
	["Rádio AM", "http://wmsint.webtvcn.com/radioam"],
	["Rádio FM", "http://wmsint.webtvcn.com/radiofm"]]

def random_stream
	SAMPLE_STREAMS[rand(SAMPLE_STREAMS.size-1)]	
end
	
Factory.sequence :email do |i|
	"hello#{i}@memuller.com"
end
Factory.sequence :name do |i|
	"Matheus E. M#{i}"
end
Factory.sequence :username do |i|
	"memuller#{i}"
end

Factory.sequence :password do |p|
	pass = ""
	15.times do |i|
		next if rand(2) == 2
		pass << rand(95)
	end
	pass
end

Factory.define :valid_app, :class => Application do |f|
	f.name {Factory.next :name}	
	f.password {Factory.next :password}
	f.username {Factory.next :username}	
end

Factory.define :valid_stream, :class => Stream do |f|
	r = random_stream
	f.title {r.first}
	f.url {r.last}
end