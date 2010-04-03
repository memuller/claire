module HasOptions
  
  def self.included(base)
    base.class_eval do
      attr_accessor :options
    end
  end
  
  def []v
    options[v]
  end

  def []=v,k
    options[v]=k
  end
end