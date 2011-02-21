module Kernel  
  if !respond_to?(:require_relative)  # supported already in Ruby 1.9.2
    define_method(:require_relative) do |path|
      require File.expand_path(File.join(File.dirname(caller[0]), path.to_str))
    end
  end
end
