class Object  #:nodoc:all
  # An object is blank if it's false, empty, or a whitespace string.
  # For example, "", "   ", +nil+, [], and {} are blank.
  #
  # This simplifies
  #
  #   if !address.nil? && !address.empty?
  #
  # to
  #
  #   if !address.blank?
  #:nodoc
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end

  # An object is present if it's not blank.
   #:nodoc
  def present?
    !blank?
  end
end

class NilClass #:nodoc
   #:nodoc
  def blank?
    true
  end
end

class FalseClass #:nodoc
   #:nodoc
  def blank?
    true
  end
end

class TrueClass #:nodoc
   #:nodoc
  def blank?
    false
  end
end

class Array #:nodoc
   #:nodoc
  alias_method :blank?, :empty?
end

class Hash #:nodoc
   #:nodoc
  alias_method :blank?, :empty?
end

class String #:nodoc
   #:nodoc
  def blank?
    self !~ /\S/
  end
end

class Numeric #:nodoc
   #:nodoc
  def blank?
    false
  end
end
