require 'fileutils'

unless Object.const_defined?('STATE_FU_APP_PATH')
  STATE_FU_APP_PATH = Object.const_defined?('RAILS_ROOT') ? RAILS_ROOT : File.join( File.dirname(__FILE__), '/../..')
end

unless Object.const_defined?('STATE_FU_PLUGIN_PATH')
  STATE_FU_PLUGIN_PATH = Object.const_defined?('RAILS_ROOT') ? File.join( RAILS_ROOT, '/vendor/plugins/state-fu' ) : STATE_FU_APP_PATH
end

begin
  require 'rake'
  require 'spec'
  require 'spec/rake/spectask'

  namespace :spec do
    def find_last_modified_spec
      require 'find'
      specs = []
      Find.find( File.expand_path(File.join(STATE_FU_APP_PATH,'spec'))) do |f|
        next unless f !~ /\.#/ && f =~ /_spec.rb$/
        specs << f
      end
      spec = specs.sort_by { |spec| File.stat( spec ).mtime }.last
    end

    desc "runs the last modified spec; L=n runs only that line"
    Spec::Rake::SpecTask.new(:last) do |t|
      specfile = find_last_modified_spec || return
      t.verbose = true
      t.spec_opts = ["-c","-b","-u"]
      if ENV['L']
        t.spec_opts += ["-l", ENV["L"],"-f", "specdoc"]
      else
        t.spec_opts += ["-f", "profile"]
      end
      t.spec_files = FileList[specfile]
    end

    desc "runs all specs, or those which last failed"
    Spec::Rake::SpecTask.new(:faily) do |t|
      specfile    = find_last_modified_spec || return
      faily       = 'spec.fail'
      t.verbose   = true
      t.spec_opts = ["-f","failing_examples:#{faily}", "-f","n","-c","-b","-u"]
      if File.exists?(faily) && File.read(faily).split("\n")[0] != ""
        t.spec_opts << ["-e",faily]
      end
    end
  end

rescue LoadError
  # fail quietly if rspec is not installed
end

