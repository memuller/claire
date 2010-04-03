require 'tempfile'

module StateFu
  class Plotter
    attr_reader :machine, :dot, :graph, :states, :events

    OUTPUT_HELPER = Module.new do

      def save!
        Tempfile.new(['state_fu_graph','.dot']) do |fh|
          fh.write( self )
        end.path
      end

      def save_as( filename )
        File.open(filename, 'w') { |fh| fh.write( self ) }
      end

      def save_png(filename)
        raise NotImplementedError
        # dot graph.dot -Tpng -O
      end

    end

    def output
      generate
    end

    def initialize( machine, options={} )
      raise RuntimeError, machine.class.to_s unless machine.is_a?(StateFu::Machine)
      @machine = machine
      @options = options.symbolize_keys!
      @states  = {}
      @events  = {}
      # generate
    end

    def generate
      @dot ||= generate_dot!.extend( OUTPUT_HELPER )
    end

    def generate_dot!
      @graph = Vizier::Graph.new(:state_machine) do |g|
        g.node :shape => 'doublecircle'
        machine.state_names.map.each do |s|
          @states[s] = g.add_node(s.to_s)
        end
        machine.events.map.each do |e|
          e.origins.map(&:name).each do |from|
            e.targets.map(&:name).each do |to|
              g.connect( @states[from], @states[to], :label => e.name.to_s )
            end
          end
          # @events[s] = g.add_node(s.to_s)
        end
      end
      @graph.generate!
    end

  end
end
