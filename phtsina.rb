#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'pp'
require 'date'
require 'trollop'
require 'open-uri'
require 'nokogiri'
require 'fileutils'

opts = Trollop::options do
  opt :check, "Check", :short => "-c", :default => true
  opt :competition, "Competition", :short => "-g", :type => :string, :default => "英超"
  opt :query, "Query", :short => "-q", :type => :string, :default => "曼联"
  opt :page, "Page Max", :short => "-p", :default => 2
  opt :url, "URL", :short => "-u", :type => :string
end

shortcode = { :英超 => "pl", :欧冠 => "cl" }
base_dir = "/tmp/phtsina_#{$$}"
FileUtils.mkdir_p base_dir
diary_dir = "#{ENV["HOME"]}/Documents/Diary/#{Date.today.year}"

if not opts[:url].nil?
  doc = Nokogiri::HTML(open(opts[:url]))
  puts doc.title
  title = (doc.title.split('_'))[0]
  puts (Date.today.year.to_s+("%02d" % Date.today.month)+("%02d" % Date.today.day)).sub(/^../,'')
  doc.xpath('//div[@id = "wrap"]/div[@id = "eData"]/dl').each do |pb|
    pb.children.each do |child|
      child.children.each do |pic|
        link = pic.to_s
        if link =~ /2_img/
          open(File.join(base_dir, File.basename(link)), 'wb') do |img|
            img << open(link).read
          end
        end
      end
    end
  end
  outfile = ""
  print "enter output file name: "
  outfile = gets
  outfile = outfile.strip + ".png"
  puts outfile
  system("montage -shadow #{base_dir}/*.jpg #{File.join(diary_dir, outfile)}")
  system("touch #{File.join(diary_dir, "@sports_"+title+"_"+outfile)}")
  exit
end

1.upto(opts[:page]) do |pg|
  FileUtils.mkdir_p File.join(base_dir, pg.to_s)
  doc = Nokogiri::HTML(open("http://slide.sports.sina.com.cn/g/#{pg}.html"))
  doc.xpath('//div/div[@class ="partB"]/div[@class = "content"]/div[@class = "picBox"]/h2/a').each do |pb|
    title = pb.attributes["title"].value
    next unless opts[:competition].empty? or title =~ /\[#{opts[:competition]}\]/
    next unless opts[:query].empty? or title =~ /#{opts[:query]}/
    if opts[:check]
      print "#{title}, skip? "
      promt_ans = gets
      next if promt_ans =~ /[yY]/
    end
    open(pb.attributes["href"].value).each_line do |l|
      next unless l =~ /<dd>/ and l =~ /2_img/
      link = l.strip.gsub(/<[^>]*>/, '')
      open(File.join(base_dir, pg.to_s, File.basename(link)), 'wb') do |img|
        img << open(link).read
      end
    end
    pref = ""
    if shortcode.has_key? opts[:competition].to_sym
      pref = shortcode[opts[:competition].to_sym]
    else
      print "enter prefix: "
      pref = gets
    end
    outfile = pref+(Date.today.year.to_s+("%02d" % Date.today.month)+("%02d" % Date.today.day)).sub(/^../,'')+"-"+title.sub(/\[#{opts[:competition]}\]/,'')+".png"
    system("montage -shadow #{File.join(base_dir, pg.to_s)}/*.jpg #{File.join(diary_dir, outfile)}")
    system("open #{File.join(diary_dir, outfile)}")
    system("touch #{File.join(diary_dir, "@sports_"+title+"_"+outfile)}")
  end
end
