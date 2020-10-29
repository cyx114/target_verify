#!/usr/bin/ruby -w
# -*- coding : utf-8 -*-
require_relative 'config'

def get_items_arr_in_folder(folder_path)
  items_arr = Array.new
  Dir.foreach(folder_path) do |file|
    if file == "." or file == ".." or file == ".DS_Store"
      next
    end
    path = File.join folder_path, file
    items_arr << path
    if File.directory? path
      items_arr += get_items_arr_in_folder path
    end
  end
  items_arr
end

def get_relative_paths_arr_in_folder(folder_path)
  paths_arr = get_items_arr_in_folder folder_path
  paths_arr.map do |path|
    path.slice! folder_path
    path
  end
end

def verify_assets(first_asset, last_asset)
  first_asset_list = get_relative_paths_arr_in_folder first_asset
  last_asset_list = get_relative_paths_arr_in_folder last_asset
  puts "\n--------\ncount:#{first_asset_list.length}, #{last_asset_list.length}\n--------\n"
  abnormal_list = first_asset_list - last_asset_list - $asset_ignore_keys
  reverse_abnormal_list = last_asset_list - first_asset_list - $asset_reverse_ignore_keys
  return abnormal_list, reverse_abnormal_list
end

def print_list_shapely a_list
  puts "\n============"
  a_list.each do |item|
    puts item
  end
  puts "============"
end

if __FILE__ == $0
  first_file = ARGV[0]
  last_file = ARGV[1]
  # for DEBUG convenience
  if first_file.nil? or last_file.nil?
    first_file = "<#debug path#>"
    last_file = first_file = "<#debug path#>"
  end
  abnormal_list, reverse_abnormal_list = verify_assets first_file, last_file
  first_file_name = (first_file.split"/")[-1]
  last_file_name = (last_file.split"/")[-1]
  puts "#{first_file_name} greater than #{last_file_name}:"
  print_list_shapely abnormal_list
  puts "\n#{last_file_name} greater than #{first_file_name}:"
  print_list_shapely reverse_abnormal_list
  if abnormal_list.length > 0 or reverse_abnormal_list.length > 0
    raise "files not match, please check the log for detail"
  end
end


