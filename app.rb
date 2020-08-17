#!/usr/bin/env ruby

require 'sinatra'
require 'json'
require 'securerandom'
require 'fileutils'

set :port, 8080
set :bind, '0.0.0.0'

def test_string
  SecureRandom.hex
end

def testfile?
  !ENV['VOLUME_TEST_FILE'].nil?
end

def testfile
  ENV['VOLUME_TEST_FILE']
end

get '/*' do
  if testfile?
    begin
      ts = test_string
      FileUtils.mkdir_p(File.dirname(testfile))
      File.write(testfile, ts)
      read_val = File.read(testfile).chomp
      ok = ts == read_val ? "OK" : "Failed"
      return "Read/Write: #{ok} - Test contents: #{ts}\n"
    rescue StandardError => e
      return "Exception encountered reading/writing to '#{testfile}': #{e.message}\n"
    end
  else
    return "Env var VOLUME_TEST_FILE not set. Set it to desired test file location and try again\n"
  end
end
