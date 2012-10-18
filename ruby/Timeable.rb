require 'benchmark'

module Timeable
  @@func_calls       = Hash.new(0)
  @@func_total_times = Hash.new(0)
  @@func_sys_times   = Hash.new(0)
  @@func_user_times  = Hash.new(0)
  @@iterations       = Hash.new(1)
  @@resets_after_display = false
  
  ######################################################################
  # time_methods *meths
  #
  # times methods given as argument 
  #
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
  
  ######################################################################
  # time_block block_name, &block
  #
  # times a block (must pass a block_name)
  #
  def self.time_block(block_name)
    start_time = Time.now
    value = yield
    @@func_total_times[block_name] += Time.now - start_time
    @@func_calls[block_name] += 1
    Timeable::show_times
    Timeable::reset_times if @@resets_after_display
    value
  end
  
  ######################################################################
  # set_iterations (method, n)
  #
  # to be displayed after n iterations
  #
  def set_iterations(method, n)
    return false if n < 1
    @@iterations[method] = n
  end

  ######################################################################
  # display_time after (*meths)
  #
  # select methods to display time when finish (with set iterations)
  #
  def display_time_after meth
    alias_method "timeable_display_#{meth}", meth
    
    define_method meth do |*args|
      value = send "timeable_display_#{meth}", *args
      Timeable::show_times if Timeable::time_to_show?(meth)
      Timeable::reset_times if @@resets_after_display
      value
    end
  end
  
  ######################################################################
  # reset_times_after (*meths)
  #
  # reset times after method(s) have been called (with set iterations)
  def reset_times_after_display
      @@resets_after_display = true
  end
  
  def self.time_to_show?(meth)
    @@iterations[meth] > 0 && ((@@func_calls[meth] % @@iterations[meth]) == 0)
  end
  
  def self.show_times
    col_method = "Method"
    col_calls = "Calls"
    col_time = "Total Time"
    col_cs = "Calls/Sec"
    col_sc = "Seconds/Call"
    
    max_name_size = col_method.length
    max_time_size = col_time.length
    max_call_size = col_calls.length
    max_cs_size   = col_cs.length
    max_sc_size   = col_sc.length
    
    times = @@func_total_times.sort_by do |name, time|
      calls = @@func_calls[name]
      max_name_size = [name.to_s.length, max_name_size].max
      max_time_size = [time.to_i.to_s.length, max_time_size].max
      max_call_size = [calls.to_s.length, max_call_size].max
      v = (time == 0) ? 0 : calls/time
      max_cs_size = [v.to_i.to_s.length, max_cs_size].max
      v = (calls == 0) ? 0 : time/calls
      max_sc_size = [v.to_i.to_s.length, max_sc_size].max
    end
    
    column_labels = "%-#{max_name_size}s %#{max_call_size}s %#{max_time_size+3}s %#{max_cs_size+3}s %#{max_sc_size+3}s\n"
    msg       = "%-#{max_name_size}s %#{max_call_size}d %#{max_time_size+3}.3f %#{max_cs_size+3}.3f %#{max_sc_size+3}.3f\n"
    total_size = max_name_size + max_call_size + max_time_size + max_cs_size + max_sc_size + 13
    
    puts
    puts "-" * total_size
    printf column_labels , col_method, col_calls, col_time, col_cs, col_sc
    times.each do |name, time|
      calls = @@func_calls[name]
      next if calls == 0
      printf msg, name, calls, time, ((time == 0) ? 0 :  calls/time), time/calls
    end
    puts "-" * total_size
    puts
  end
  
  ######################################################################
  # self.reset_times
  #
  # reset all times 
  #
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
    for i in 1..5
      choose
    end
  end
  
  def blockSample
    for i in 1..3
      Timeable.time_block('sample_block') {
        run
      }
    end
  end
end

Foo.extend Timeable
Foo.time_methods :run, :choose, :a, :b
#Foo.display_time_after :run
Foo.reset_times_after_display

#o = Foo.new
#o.run
#o.run
o2 = Foo.new
#o2.run

o2.blockSample
o2.blockSample
