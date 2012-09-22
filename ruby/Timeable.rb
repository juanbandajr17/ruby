require 'benchmark'

module Timeable
  @@func_calls       = Hash.new(0)
  @@func_total_times = Hash.new(0)
  @@func_sys_times   = Hash.new(0)
  @@func_user_times  = Hash.new(0)
  @@iterations       = Hash.new(1)
  @@resets_at        = Hash.new(false)
  
  def time_methods *meths
    meths.each do |meth|
      alias_method "timeable_time_#{meth}", meth

      define_method meth do |*args|
        start_time = Time.now
        value = send "timeable_time_#{meth}", *args
        @@func_total_times[meth] += Time.now - start_time
        @@func_calls[meth] += 1
        value
      end
    end
  end  
  
  def set_iterations(method, n)
    return false if n < 1
    @@iterations[method] = n
  end
  
  def display_time_after *meths
    meths.each do |meth|
      alias_method "timeable_display_#{meth}", meth
      
      define_method meth do |*args|
        value = send "timeable_display_#{meth}", *args
        Timeable::show_times if Timeable::time_to_show?(meth)
        Timeable::reset_times if Timeable::time_to_reset?(meth)
        value
      end
    end
  end
  
  def reset_times_after *meths
    meths.each do |meth|
      @@resets_at[meth] = true
    end
  end
  
  def self.time_to_reset?(meth)
    Timeable::time_to_show?(meth) && @@resets_at[meth]
  end
  
  def self.time_to_show?(meth)
    @@iterations[meth] > 0 && ((@@func_calls[meth] % @@iterations[meth]) == 0)
  end
  
  def self.show_times
    col_method = "Method"
    col_calls = "Calls"
    col_time = "Total Time"
    col_cs = "Calls/Sec"
    
    max_name_size = col_method.length
    max_time_size = col_time.length
    max_call_size = col_calls.length
    max_cs_size = col_cs.length
    
    times = @@func_total_times.sort_by do |name, time|
      max_name_size = [name.to_s.length, max_name_size].max
      max_time_size = [time.to_i.to_s.length, max_time_size].max
      max_call_size = [@@func_calls[name].to_s.length, max_call_size].max
      v = (time == 0) ? 0 : @@func_calls[name]/time
      max_cs_size = [v.to_i.to_s.length, max_cs_size].max
      v
    end
    
    col_names = "%-#{max_name_size}s %#{max_call_size}s %#{max_time_size+3}s %#{max_cs_size+3}s\n"
    msg       = "%-#{max_name_size}s %#{max_call_size}d %#{max_time_size+3}.3f %#{max_cs_size+3}.3f\n"
    total_size = max_name_size + max_call_size + max_time_size + max_cs_size + 10
    
    puts
    puts "-" * total_size
    printf col_names , col_method, col_calls, col_time, col_cs
    times.each do |name, time|
      printf msg, name, @@func_calls[name], time, (time == 0) ? 0 :  @@func_calls[name]/time
    end
    puts "-" * total_size
    puts
  end
  

  def self.reset_times
    @@func_calls.each do |k, v|
      @@func_calls[k] = 0
      @@func_total_times[k] = 0
    end
  end
end



############### TESTING ###################

class Foo
  def a
    sleep(1)
  end
  
  def b
    sleep(2)
  end
  
  def choose
    r = 1 + rand(100)
    if r < 51
      a()
    else
      b()
    end
  end
  
  def run
    for i in 1..10
      choose
    end
  end
end

Foo.extend Timeable
Foo.time_methods :run, :choose, :a, :b
Foo.display_time_after :run
Foo.reset_times_after :run

o = Foo.new
o.run
o.run
o2 = Foo.new
o2.run
