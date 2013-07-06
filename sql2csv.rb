#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'yaml'
require 'sequel'
require 'trollop'

opts = Trollop::options do
  opt :host, "Host", :short => "-h", :type => :string, :default => "localhost"
  opt :db, "Database", :short => "-d", :type => :string, :required => true
  opt :tbl, "Table", :short => "-t", :type => :string, :required => true
  opt :sep, "Separator", :short => "-s", :type => :string, :default => ","
  opt :noheader, "No Header", :short => "-n", :default => false
  opt :output, "Output", :short => "-o", :type => :string
  opt :sql, "Additional SQL Clause", :short => "-q", :type => :string, :default => ""
end

# check field separator: TAB or Comma
if opts[:sep] =~ /^[Tt]/
  opts[:sep] = '\t'
else
  opts[:sep] = ','
end

# determine output file and temp file
ofile = Dir.pwd + "/" + (opts[:output] || opts[:tbl]) + ".csv"
tfile = Dir.pwd + "/." + (opts[:output] || opts[:tbl]) + ".bak"
if File.exist? ofile
  puts "File #{ofile} exists. Replace it?"
  response = gets
  unless response =~ /[yY]/
    puts "File exists. Exit."
    exit 1
  end
  system("rm -rf #{ofile}")
end

# mysql login conf
sql_conf = {}
File.open("#{ENV["HOME"]}/.mysql_logins/#{opts[:host]}", "r") { |f| sql_conf = YAML.load(f) }
sql_conf["DBName"] = opts[:db]
# mysql connection
mydb = Sequel.mysql2(sql_conf["DBName"], :user => sql_conf["DBID"], :password => sql_conf["DBPW"], :host => sql_conf["DBServer"])
# select mysql dataset
mytbl = mydb[opts[:tbl]]

# determine which column(s) to output
cols_all = mydb.fetch("show columns from #{opts[:tbl]}").map(:Field)
puts "The columns are:"
puts "  " + cols_all.join(",")
puts
puts "Enter a comma separated string of column names:"
cols_str = gets
cols_str.strip!
if cols_str.empty? or cols_str =~ /[Aa]ll/
  cols_sel = cols_all
else
  cols_sel = cols_str.split(",")
end

# generate output
unless opts[:noheader]
  header = cols_sel.join("#{opts[:sep]}")
  system("echo '#{header}' > #{ofile}")
end
mydb.run("select #{cols_sel.join(",")} from #{opts[:tbl]} #{opts[:sql].empty? ? "" : opts[:sql]} into outfile '#{tfile}' fields terminated by '#{opts[:sep]}' optionally enclosed by '\"'")
system("cat #{tfile} >> #{ofile}")
system("rm -rf #{tfile}")
