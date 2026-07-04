#!/usr/bin/env ruby
# frozen_string_literal: true

paths = ARGV.empty? ? Dir.glob('db/migrate/**/*.rb') + Dir.glob('db/schema.rb') : ARGV
violations = []

paths.each do |path|
  next unless File.file?(path)

  File.readlines(path).each_with_index do |line, index|
    if line.match?(/\b(?:t\.)?(?:string|integer|bigint|text)\s+['"]status['"]/) ||
       line.match?(/\badd_column\b.*['"]status['"]/) ||
       line.match?(/\bcreate_enum\b.*['"]status['"]/) ||
       line.match?(/\bstatus:\s/)
      violations << "#{path}:#{index + 1}: avoid generic status columns; see decisions/0001-no-status-column.md"
    end
  end
end

if violations.empty?
  puts 'check_schema: no generic status columns found'
  exit 0
end

warn violations.join("\n")
exit 1
