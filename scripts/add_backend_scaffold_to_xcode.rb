#!/usr/bin/env ruby
require "pathname"

begin
  require "xcodeproj"
rescue LoadError
  warn "xcodeproj gem is not installed. Install it with: gem install xcodeproj"
  exit 2
end

root = Pathname.new(ARGV[0] || Dir.pwd)
project_path = root.join("iSH.xcodeproj")
abort("Missing #{project_path}") unless project_path.exist?

project = Xcodeproj::Project.open(project_path.to_s)

group_backend = project.main_group.find_subpath("backend", true)
group_rootfs  = project.main_group.find_subpath("rootfs", true)
group_loader  = project.main_group.find_subpath("loader", true)
group_app     = project.main_group.find_subpath("app", true)

files = {
  group_backend => %w[
    backend/backend.h
    backend/backend_registry.c
    backend/backend_ish_x86.c
    backend/backend_linux64_stub.c
    backend/backend_linux64_aarch64.c
    backend/backend_linux64_x86_64.c
  ],
  group_rootfs => %w[
    rootfs/rootfs_manifest.h
    rootfs/rootfs_manifest.c
  ],
  group_loader => %w[
    loader/elf64.h
    loader/elf64.c
  ],
  group_app => %w[
    app/backend_bootstrap.h
    app/backend_bootstrap.c
  ]
}

targets = project.targets.select { |t| ["iSH", "libiSHApp", "libish", "libish_emu", "iSHFileProvider"].include?(t.name) }

files.each do |group, paths|
  paths.each do |rel|
    ref = group.files.find { |f| f.path == rel } || group.new_file(rel)
    ext = File.extname(rel)
    next if ext == ".h"
    targets.each do |target|
      phase = target.source_build_phase
      unless phase.files_references.include?(ref)
        phase.add_file_reference(ref, true)
      end
    end
  end
end

project.save
puts "Updated #{project_path}"
