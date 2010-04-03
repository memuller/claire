#!/usr/bin/env ruby

begin
  require File.join(File.dirname(__FILE__), 'core_ext' )
rescue LoadError
  require 'activesupport'
end

# Vizier is a simple library to help generate dot output for graphviz. It is used by StateFu's rake 
# tasks to generate graphs of state machines.
#
# Sorry, there's only Heisendocumentation (if I realize anyone's looking for docs, I might write some)
#
module Vizier  #:nodoc:all

  module Support
    LEGAL_CHARS = 'a-zA-Z0-9_'

    def attributes=( attrs )
      @attributes = attrs.symbolize_keys!.extend( Attributes )
    end

    def attributes
      (@attributes ||= {}).extend( Attributes )
    end

    def legal?( str )
      str = str.to_s
      str =~ /^[#{LEGAL_CHARS}]+$/ && str == str.split
    end

    def sanitize(str)
      sanitize( str )
    end

    def quote( str )
      return str if legal?( str )
      '"' + str.to_s.gsub(/"/,'\"') + '"'
    end

    def self.included( klass )
      klass.extend( ClassMethods )
    end

    module Finder
      def []( idx )
        begin
          super( idx )
        rescue TypeError => e
          if idx.is_a?( String ) || idx.is_a?( Symbol )
            self.detect { |i| i.name.to_s == idx.to_s }
          elsif idx.class.respond_to?(:table_name)
            self.detect { |i| i.name.to_s == Vizier::Node.make_name( idx ) }
          else
            raise e
          end
        end
      end
    end

    module ClassMethods
      def sanitize( str )
        str.to_s.gsub(/[^#{LEGAL_CHARS}]/,'_').gsub(/__+/,'_')
      end

      def finder( name )
        class_eval do
          define_method name do
            instance_variable_get( "@#{name}" ).extend( Finder )
          end
        end
      end
    end
  end

  module Attributes
    include Support

    def to_s
      return '[]' if empty?
      '[ ' + self.map do |k,v|
        "#{quote k} = #{quote v}"
      end.join(" ") + ' ]'
    end

  end

  class Base
    def [](k)
      attributes[k.to_sym]
    end

    def []=(k,v)
      attributes[k.to_sym] = v
    end
  end

  class Link < Base
    include Support
    attr_accessor :from
    attr_accessor :to

    def initialize( from, to, attrs={} )
      self.attributes = attrs
      @from = extract_name( from )
      @to = extract_name( to )
    end

    def extract_name( o )
      o.is_a?(String) ? o : o.name
    end

    def to_str
      "#{quote from} -> #{quote to} #{attributes};"
    end
  end

  # TODO ..
  module Label
    def []( i )

    end
  end

  class Node < Base
    include Support

    attr_accessor :object
    attr_accessor :fields
    attr_accessor :name

    def initialize( name = nil, attrs={} )
      self.attributes = attrs
      if name.is_a?( String )
        self.name = name
        @label = attrs.delete(:label) || name
      else
        @object = name
        self.name = Node.make_name( @object )
        @label = attrs.delete(:label) || Node.first_response( @object, :name, :identifier, :label ) || name
      end
    end

    def self.make_name( obj )
      sanitize [ obj.class, first_response( obj, :name, :identifier, :id, :hash)].join('_')
    end

    def self.first_response obj, *method_names
      responder = method_names.flatten.detect { |m| obj.respond_to?(m) }
      obj.send( responder ) unless responder.nil?
    end

    def name=( str )
      @name = str.to_s.gsub(/[^a-zA-Z0-9_]/,'_').gsub(/__+/,'_')
    end

    def to_str
      "#{quote name} #{attributes.to_s};"
    end

    def to_s
      quote( name )
    end
  end

  class SubGraph < Base
    include Support

    finder :nodes

    attr_accessor :links
    attr_accessor :name

    def initialize( name, attrs={} )
      self.attributes = attrs
      @node = {}
      @edge = {}

      @name = name
      @nodes = []
      @links = []
    end

    def node(attrs={})
      (@node ||= {}).merge!(attrs).extend(Attributes)
    end

    def graph(attrs={})
      self.attributes.merge!(attrs).extend(Attributes)
    end

    def edge(attrs={})
      (@edge ||= {}).merge!(attrs).extend(Attributes)
    end

    def add_node( n, a={} )
      returning Node.new(n,a) do |n|
        @nodes << n
      end
    end

    def add_link(from, to, a={})
      returning Link.new( from, to, a) do |l|
        @links << l
      end
    end
    alias_method :connect, :add_link
    alias_method :add_edge, :add_link

    def build(lines = [], indent = 0)
      lines.map do |line|
        if line.is_a?( Array )
          build( line, indent + 1)
        else
          (" " * (indent * 4) ) + line.to_s
        end
      end.join("\n")
    end

    def write_comment( str, j = 0 )
      l = 40 - (j * 4)
      i = ' ' * (j * 4)
      "\n#{i}/*#{'*'*(l-2)}\n#{i}** #{ str.ljust((l - (6) - (j*4)),' ') }#{i} **\n#{i}#{'*'*(l-1)}/"
    end

    def comment(str)
      write_comment(str, 2)
    end

    def to_str
      build( ["subgraph #{quote name} {",
              [ # attributes.map {|k,v| "#{quote k} = #{quote v};" },
               ["graph #{attributes};",
                 "node #{node};",
                 "edge #{edge};"
                ],
                nodes.map(&:to_str),
                links.map(&:to_str),
                "}"
               ],
            ])
    end
    alias_method :generate!, :to_str

  end

  class Graph < SubGraph
    finder :subgraphs

    def comment( str )
      write_comment( str, 1 )
    end

    def to_str
      build(["digraph #{quote name} {",
             [
              comment("global options"),
              "graph #{graph};",
              "node #{node};",
              "edge #{edge};"
             ],
             comment("nodes"),
             nodes.map(&:to_str),
             comment("links"),
             links.map(&:to_str),
             comment("subgraphs"),
             subgraphs.map(&:to_str),
             "}"])
    end
    alias_method :generate!, :to_str

    def publish!( a = {} )
      generate! # -> png
    end

    def subgraph(name, a = {})
      returning( SubGraph.new(name, a)) do |g|
        @subgraphs << g
        yield g if block_given?
      end
    end

    def cluster(name = nil, a = {}, &block)
      if name && name = "cluster_#{name}"
        subgraph( name, a, &block )
      else
        clusters
      end
    end

    def clusters
      @subgraphs.select {|s| s.name =~ /^cluster_/ }.extend( Finder )
    end

    def initialize(name = 'my_graph', attrs = {})
      @subgraphs = []
      super( name, attrs )
      yield self if block_given?
    end
  end
end
