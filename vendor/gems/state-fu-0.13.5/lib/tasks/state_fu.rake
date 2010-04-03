require 'fileutils'

unless Object.const_defined?('STATE_FU_APP_PATH')
  STATE_FU_APP_PATH = Object.const_defined?('RAILS_ROOT') ? RAILS_ROOT : File.join( File.dirname(__FILE__), '/../..')
end

unless Object.const_defined?('STATE_FU_PLUGIN_PATH')
  STATE_FU_PLUGIN_PATH = Object.const_defined?('RAILS_ROOT') ? File.join( RAILS_ROOT, '/vendor/plugins/state-fu' ) : STATE_FU_APP_PATH
end

namespace :state_fu do

  task :update do
    path = STATE_FU_PLUGIN_PATH
    pwd = FileUtils.pwd
    FileUtils.cd( path )
    system('git pull')
    FileUtils.cd pwd
  end

  def graph_name( klass, machine, doc_path = false )
    parts = ["#{klass}_#{machine}"]
    if doc_path
      folder = parts.unshift( File.join( STATE_FU_APP_PATH, "doc/") )
      FileUtils.mkdir_p( folder )
      parts.push( '.png' )
    end
    parts.join
  end

  def graph( klass, machine )
    name = graph_name( klass, machine )
    graphviz = `which dot`.strip || raise("Graphviz not installed? Can't find dot executable!")
    puts graphviz
    tmp_dot  = "/tmp/#{name}.dot"
    klass.machine( machine.to_sym ).graphviz.save_as( tmp_dot )
    tmp_png = tmp_dot + '.png'
    doc_png = graph_name( klass, machine, true )
    puts( "#{graphviz} -Tpng -O #{tmp_dot}" )
    system( "#{graphviz} -Tpng -O #{tmp_dot}" )
    FileUtils.cp tmp_png, doc_png
    doc_png
  end

  desc "Graph workflows with dot"
  task :graph => :environment do |t|    
    state_fu_classes = ObjectSpace.each_object { |o| x << o  if o.respond_to? :machines }
    state_fu_classes.each do |klass| 
      klass.state_fu_machines.each do |machine_name, machine|
        STDERR.puts "#{klass} -> #{machine_name.inspect}"
        doc_png = graph( klass, machine_name )
        # yield doc_png if block_given?
      end
    end
    # `open #{doc_png}`
  end
end
