class String  #:nodoc:all
   #:nodoc
  def underscore
    self.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
  end

   #:nodoc
  def demodulize
    gsub(/^.*::/, '')
  end

   #:nodoc
  def constantize
    unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ self
      raise NameError, "#{self} is not a valid constant name!"
    end
    Object.module_eval("::#{$1}", __FILE__, __LINE__)
  end

   #:nodoc
  def classify # DOES NOT SINGULARISE
    camelize(self.sub(/.*\./, ''))
  end

   #:nodoc
  def camelize( first_letter_in_uppercase = true)
    if first_letter_in_uppercase
      gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
    else
      first + camelize(lower_case_and_underscored_word)[1..-1]
    end
  end

end
