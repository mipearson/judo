module Extras
  module Benchmark
    
    def bench_all_methods
      bench_methods(*public_instance_methods(false))
    end
    
    def bench_methods(*methods)
      return unless ENV['BENCH_METHODS']
      
      first_init = (!defined? @@_benchmark)
      
      @@_benchmark ||= {}
      methods.each do |method|
        method_name = "#{name}.#{method}"

        aliased_method = "old_#{method}".to_sym
        alias_method aliased_method, method
        @@_benchmark[method_name] = {:count => 0, :time_taken => 0}
        define_method method do |*args|
          start = Time.now
          result = send(aliased_method, *args)
          taken = Time.now - start
          @@_benchmark[method_name][:count] += 1
          @@_benchmark[method_name][:time_taken] += taken
          result
        end
      end
      if first_init
        Kernel.at_exit do
          $stderr.puts "*** BENCHMARK RESULTS ***"

          @@_benchmark.each do |method, vals|
            next if vals[:count] == 0 or vals[:time_taken] < 0.01
            $stderr.puts sprintf "%50s %4d times, %0.2f seconds.", method, vals[:count], vals[:time_taken]
          end
        end
      end
    end
  end
end