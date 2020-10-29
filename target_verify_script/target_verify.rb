#!/usr/bin/ruby -w
# -*- coding : utf-8 -*-
$VERBOSE=nil

require 'xcodeproj'
require 'pathname'
require_relative 'config'

$should_interrupt = false

$pbx_sources_class = Xcodeproj::Project::Object::PBXSourcesBuildPhase
$pbx_frameworks_class = Xcodeproj::Project::Object::PBXFrameworksBuildPhase
$pbx_resources_class = Xcodeproj::Project::Object::PBXResourcesBuildPhase

$ignore_file_dic = {
    $pbx_sources_class => $sources_ignore_arr,
    $pbx_frameworks_class => $frameworks_ignore_arr,
    $pbx_resources_class => $resources_ignore_arr,
}

$reverse_ignore_file_dic = {
    $pbx_sources_class => $reverse_sources_ignore_arr,
    $pbx_frameworks_class => $reverse_frameworks_ignore_arr,
    $pbx_resources_class => $reverse_resources_ignore_arr,
}

# @return [a bool value indicates whether oir_path is in ignore_arr]
def file_should_ignore(ori_path, ignore_arr)
  unless ori_path.is_a?(String)
    puts "=====#{ori_path.class}"
    return true
  end
  ignore_arr.each do |ignore_path|
    pure_ignore_path = ignore_path.strip
    pure_ori_path = ori_path.strip
    # 因为忽略列表中为相对地址，故需要找到文件路径中相对路径的起始位置
    from_index = pure_ori_path.length - pure_ignore_path.length
    next if from_index < 0
    interception_path = ori_path[from_index..-1]
    # puts "#{interception_path} ==> #{pure_ignore_path}"
    if ignore_arr.include? interception_path
      # puts "ignore file:#{ori_path}"
      return true
    end
  end
  false
end

def resolve_ignore_files(lack_arr, ignore_arr)
  lack_arr.select do |ori_path|
    !file_should_ignore ori_path, ignore_arr
  end
end

def file_arr_for_target(target, class_obj)
  if class_obj == $pbx_sources_class
    phase = target.source_build_phase
  elsif class_obj == $pbx_frameworks_class
    phase = target.frameworks_build_phase
  elsif class_obj == $pbx_resources_class
    phase = target.resources_build_phase
  else
    raise "unknown recognize class"
  end
  # puts phase
  file_arr = Array.new
  phase.files.to_a.each do |pbx_build_file|
    begin
      if pbx_build_file.file_ref.is_a?(Xcodeproj::Project::Object::PBXVariantGroup)
        pbx_build_file.file_ref.children.each do |item|
          file_arr << item.real_path.to_s
        end
      else
        file_arr << pbx_build_file.file_ref.real_path.to_s
      end
    rescue
      # 部分值不是PBXVariantGroup类，也不是PBXFileReference 类，会处理失败走到这里，对比源文件为空值，暂不处理。
      next
    end
  end
  return file_arr
end

def compare_arr(first_file_arr, last_file_arr, class_obj, target_first, target_last)
  lack_arr = first_file_arr - last_file_arr
  ignore_arr = $ignore_file_dic[class_obj]
  abnormal_arr = resolve_ignore_files(lack_arr, ignore_arr)
  if abnormal_arr.size > 0
    puts "\n========Abnormal========"
    puts "#{class_obj.to_s}\nfiles #{target_first.name} greater than #{target_last.name}, count:#{abnormal_arr.size}\n"
    abnormal_arr.each do |file|
      puts file
    end
    puts "========Abnormal========"
    $should_interrupt = true
  end
end

def compare_arr_reverse(first_file_arr, last_file_arr, class_obj, target_first, target_last)
  lack_arr = last_file_arr - first_file_arr
  ignore_arr = $reverse_ignore_file_dic[class_obj]
  abnormal_arr = resolve_ignore_files(lack_arr, ignore_arr)
  if abnormal_arr.size > 0
    puts "\n========Abnormal========"
    puts "#{class_obj.to_s}\nfiles #{target_last.name} greater than #{target_first.name}, count:#{abnormal_arr.size}\n}"
    abnormal_arr.each do |file|
      puts file
    end
    puts "========Abnormal========"
    $should_interrupt = true
  end
end


def compare_resources_for_class(target_first, target_last, class_obj)
  first_file_arr = file_arr_for_target(target_first, class_obj)
  last_file_arr = file_arr_for_target(target_last, class_obj)
  puts "\n\n-----------------------\n#{class_obj.to_s} count, first:#{first_file_arr.size} last:#{last_file_arr.size}"
  puts "-----------------------"
  compare_arr first_file_arr, last_file_arr, class_obj, target_first, target_last
  compare_arr_reverse first_file_arr, last_file_arr, class_obj, target_first, target_last
end

def compare_target_resources(target_first, target_last)
  verify_class_arr = [$pbx_sources_class, $pbx_frameworks_class, $pbx_resources_class]
  verify_class_arr.each { |class_obj| compare_resources_for_class(target_first, target_last, class_obj) }
end

if __FILE__ == $0
  project_path = ARGV[0]
  target_name_first = ARGV[1]
  target_name_last = ARGV[2]
  # for DEBUG convenience
  project_path  = !project_path.nil? ? project_path : "<#debug path#>"
  target_name_first = !target_name_first.nil? ? target_name_first : "<#debug target name#>"
  target_name_last = !target_name_last.nil? ? target_name_last : "<#debug target name#>"
  puts project_path
  project = Xcodeproj::Project.open(project_path)
  target_first = project.targets.select { |a_target| a_target.name.eql?(target_name_first)}
  target_last = project.targets.select { |a_target| a_target.name.eql?(target_name_last)}
  compare_target_resources(target_first.first, target_last.first)
  if $should_interrupt
    raise "files not match, please check the log for detail"
  end
end

