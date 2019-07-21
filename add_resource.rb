#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'xcodeproj'

# グループを作ってその中にファイルへの参照を追加する
def add_file_refs(xcproj, parent_group, group_name, path)
  group = xcproj.new(Xcodeproj::Project::Object::PBXGroup)
  group.name = group_name
  parent_group << group

  # next unless File::exists?(path) && File::ftype(path) == 'file'
  ref = xcproj.new(Xcodeproj::Project::Object::PBXFileReference)
  ref.name = File.basename(path)
  ref.path = path
  group << ref
  return group
end

# Copy Bundle Resources にリソースを追加する
def add_copy_bundle(xcproj, targets, file_refs)
  xcproj.targets.each do |target|
    next unless targets.include? target.name

    copy_bundle_resources = target.resources_build_phase
    file_refs.each do |ref|
      copy_bundle_resources.add_file_reference(ref)
    end
  end
end

def main
  xcproj_path = ARGV.shift
  file = ARGV.shift
  targets = ARGV
  group_name = 'Resources'
  # files = ARGV

  xcproj = Xcodeproj::Project.new(xcproj_path)
  xcproj.initialize_from_file

  group = add_file_refs(xcproj, xcproj.main_group, group_name, file)
  add_copy_bundle(xcproj, targets, group.children)

  xcproj.save
end

if $0 == __FILE__
  main
end
