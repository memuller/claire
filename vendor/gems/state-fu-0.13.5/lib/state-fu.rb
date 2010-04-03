#!/usr/bin/env ruby
#
# State-Fu
#
# State-Fu is a framework for state-oriented programming in ruby.
#
# You can use it to define state machines, workflows, rules engines,
# and the behaviours which relate to states and transitions between
# them.
#
# It is powerful and flexible enough to drive entire applications, or
# substantial parts of them. It is designed as a library for authors,
# as well as users, of libraries: State-Fu goes to great lengths to
# impose very few limits on your ability to introspect, manipulate and
# extend the core features.
#
# It is also delightfully elegant and easy to use for simple things.
%w( support support/active_support_lite ).each do |path|
  $LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), path)))
end

[ 'support/core_ext',
  'support/logging',
  'support/applicable',
  'support/arrays',
  'support/has_options',
  'support/vizier',
  'support/plotter',
  'support/exceptions',
  'executioner',
  'machine',
  'blueprint',
  'lathe',
  'method_factory',
  'binding',
  'persistence',
  'persistence/base',
  'persistence/active_record',
  'persistence/attribute',
  'persistence/relaxdb',
  'sprocket',
  'state',
  'event',
  'hooks',
  'interface',
  'transition',
  'transition_query' ].each { |lib| require File.expand_path(File.join(File.dirname(__FILE__),lib))}

module StateFu
  DEFAULT       = :default
  DEFAULT_FIELD = :state_fu_field

  def self.included( klass )
    klass.extend(         Interface::ClassMethods )
    klass.send( :include, Interface::InstanceMethods )
    klass.extend(         Interface::Aliases )
  end
end

