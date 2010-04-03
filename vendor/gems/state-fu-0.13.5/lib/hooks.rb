module StateFu

  # TODO document structure / sequence of hooks elsewhere

  module Hooks  #:nodoc

    ALL_HOOKS = [[:machine, :before_all], # global before. prepare for any transition
                 [:event,   :before],     # prepare for the event
                 [:origin,  :exit],       # say goodbye!
                 [:event,   :execute],    # do stuff here for the event
                 [:target,  :entry],      # entry point. last chance to halt!
                 [:event,   :after],      # clean up after transition 
                 [:target,  :accepted],   # state is changed. Do something about it.
                 [:machine, :after_all]]  # global after. close up shop.

    EVENT_HOOKS   = ALL_HOOKS.select { |type, name| type == :event }
    STATE_HOOKS   = ALL_HOOKS.select { |type, name| [:origin, :target].include?(type) }
    MACHINE_HOOKS = ALL_HOOKS.select { |type, name| type == :machine }
    HOOK_NAMES    = ALL_HOOKS.map(&:last)

    # just turn the above into what each class needs
    # and make it into a nice hash: { :name =>[ hook, ... ], ... }
    def self.for( instance )
      case instance
      when State
        STATE_HOOKS
      when Event
        EVENT_HOOKS
      when Machine
        MACHINE_HOOKS
      when Sprocket
        []
      end.
        map { |type, name| [name, [].extend( OrderedHash )] }.
        to_h.extend( OrderedHash ).freeze
    end

  end
end
