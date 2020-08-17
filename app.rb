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

def static_test_string
  'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
end

def testfile?
  !ENV['VOLUME_TEST_FILE'].nil?
end

def testfile
  ENV['VOLUME_TEST_FILE']
end

get '/clear' do
  if testfile?
    begin
      FileUtils.mkdir_p(File.dirname(testfile))
      File.write(testfile, "")
      return "Wrote empty string to file '#{testfile}'.  Use /write to write test string\n"
    rescue StandardError => e
      return "Exception encountered reading/writing to '#{testfile}': #{e.message}\n"
    end
  else
    return "Env var VOLUME_TEST_FILE not set. Set it to desired test file location and try again\n"
  end
end

get '/read' do
  if testfile?
    begin
      read_val = File.read(testfile).chomp
      read_val = "(empty)" if read_val == ""
      ok = static_test_string == read_val ? "OK" : "Failed"
      retval = "Read: #{ok} - File contents: #{read_val} - Expected: #{static_test_string}.\n"
      retval += "If you have not written the file yet, curl /write, delete and recreate the Pod, and try /read again\n" unless ok == 'OK'
      return retval
    rescue StandardError => e
      return "Exception encountered reading/writing to '#{testfile}': #{e.message}\n"
    end
  else
    return "Env var VOLUME_TEST_FILE not set. Set it to desired test file location and try again\n"
  end
end

get '/write' do
  if testfile?
    begin
      FileUtils.mkdir_p(File.dirname(testfile))
      File.write(testfile, static_test_string)
      return "Wrote '#{static_test_string}' to file '#{testfile}'.  Delete and re-create this Pod and curl /read to verify the string persisted\n"
    rescue StandardError => e
      return "Exception encountered reading/writing to '#{testfile}': #{e.message}\n"
    end
  else
    return "Env var VOLUME_TEST_FILE not set. Set it to desired test file location and try again\n"
  end
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
