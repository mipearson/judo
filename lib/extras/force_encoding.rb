# Grr, right_aws Ruby 1.8.7 fuckage
class String
  if !instance_methods.map {|a| a.to_sym}.include?(:force_encoding)
    define_method(:force_encoding) do |enc|
      self
    end
  end
end