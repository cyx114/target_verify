#!/usr/bin/ruby -w
# -*- coding : utf-8 -*-
require_relative 'config'

def define_dic_for_file(file_path)
  define_dic = Hash.new
  IO.foreach(file_path) do |line|
    pure_line = line.to_s.strip
    if pure_line.start_with?("#define")
      sep_arr = pure_line.split(" ", 3)
      if sep_arr.length != 3
        puts "abnormal line:#{line}"
        next
      end
      define_dic[sep_arr[1]] = sep_arr[2]
    end
  end
  # puts "================"
  # define_dic.keys.each do |key|
  #   puts key
  # end
  # puts "================"
  define_dic
end

def compare_define_for_file(first_file, last_file)
  first_define_dic = define_dic_for_file first_file
  last_define_dic = define_dic_for_file last_file
  last_lack_keys = Array.new
  first_define_dic.keys.each do |key|
    if !last_define_dic.has_key?(key)
      last_lack_keys.push(key)
    end
  end
  last_lack_keys -= $const_ignore_keys
  first_file_name = (first_file.split"/")[-1]
  last_file_name = (last_file.split"/")[-1]
  puts "\n#{first_file_name} greater than #{last_file_name}:#{last_lack_keys}"
  first_lack_keys = Array.new
  last_define_dic.keys.each do |key|
    if !first_define_dic.has_key?(key)
      first_lack_keys.push(key)
    end
  end
  first_lack_keys = first_lack_keys - $const_reverse_ignore_keys
  puts "\n#{last_file_name} greater than #{first_file_name}:#{first_lack_keys}"
  return last_lack_keys, first_lack_keys
end

if __FILE__ == $0
  first_file = ARGV[0]
  last_file = ARGV[1]
  if first_file.nil? or last_file.nil?
    first_file = "<#debug path#>"
    last_file = "<#debug path#>"
  end
  first_lack_keys, last_lack_keys = compare_define_for_file first_file, last_file
  if first_lack_keys.length > 0 or last_lack_keys.length > 0
    raise "keys in two files are not matched, please check the log upper for detail"
  end
end