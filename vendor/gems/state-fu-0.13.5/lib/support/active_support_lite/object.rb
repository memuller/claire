class Object  #:nodoc:all

   #:nodoc
  def extended_by #:nodoc
    ancestors = class << self; ancestors end
    ancestors.select { |mod| mod.class == Module } - [ Object, Kernel ]
  end
    
end
