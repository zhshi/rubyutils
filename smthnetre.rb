#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'uri'

query = URI.escape(ARGV[0])

query.gsub!('%', '%25')

cmd = 'open \'http://www.newsmth.net/nForum/#!s/article?t1='+query+'&au=&b=NetResources\''

system(cmd)
