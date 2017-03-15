# coding: utf-8
require 'logstash/devutils/rspec/spec_helper'
require 'rspec/expectations'
require 'json'

# Load the test cases
filter_data = Dir[File.join(File.dirname(__FILE__), 'filter_data/**/*.json')]

# Load the logstash filter config files
@@configuration = String.new
files = Dir[File.join(File.dirname(__FILE__), 'filter_config/*.conf')]

files.sort.each do |file|
  @@configuration << File.read(file)
end

def run_case(tcase, fields, ignore, data_file, i)
  input = fields
  input['message'] = tcase['in']

  msg_header = "[#{File.basename(data_file)}##{i}]"

  # The `sample` method is provided by
  # logstash-devutils/lib/logstash/devutils/rspec/logstash_helpers.rb.
  # The `results` variable in the block to `sample` will be the resulting
  # event after being processed by any filters present in the configuration,
  # which is initialized below in the call to `config` (also provided by
  # logstash_helpers.rb). We clone the input here since tests are run in
  # parallel.
  sample(input.clone) do
    expected = tcase['out']

    if expected.empty?
      msg = "\n#{msg_header} Expected output to be empty.\nComplete logstash output: #{results}\n--"
      expect(results).to be_empty, msg
      next # exit early from block
    end

    if results.empty?
      msg = "\n#{msg_header} No output, but expected.\nComplete expected output: #{expected}\n--"
      expect(expected).to be_empty, msg
      next # exit early from block
    end

    expected_fields = expected.keys

    results.each do |result|
      fields = result.to_hash.keys.select { |f| not ignore.include?(f) }

      # Test for presence of expected fields
      missing = expected_fields.select { |f| not fields.include?(f) }
      msg = "\n#{msg_header} Fields missing in logstash output: #{missing}\nComplete logstash output: #{result.to_hash}\n--"
      expect(missing).to be_empty, msg

      # Test for presence of unknown fields
      extra = fields.select { |f| not expected_fields.include?(f) }
      msg = "\n#{msg_header} Unexpected fields in logstash output: #{extra}\nComplete logstash output: #{result.to_hash}\n--"
      expect(extra).to be_empty, msg

      # Test individual field values
      expected.each do |name,value|
        msg = "\n#{msg_header} Field value mismatch: '#{name}'\nExpected: #{value} (#{value.class})\nGot: #{result.get(name)} (#{result.get(name).class})\n\n--"

        # If specified in the test case as an array (except for tags), check to
        # see if current output is included in the array of expected outputs.
        # TODO: track to make sure all elements in array of expected outputs are
        # accounted for (perhaps by removing them from expected as they're
        # matched?).
        if value.is_a?(Array) and name != "tags" # hack! :(
          expect(value.include?(result.get(name))).to be_truthy, msg
        else
          expect(result.get(name).to_s).to eq(value.to_s), msg
        end
      end
    end
  end
end

filter_data.each do |data_file|
  # Count test cases in this file
  test_case = JSON.parse(File.read(data_file))

  test_case['cases'].each_with_index do |tcase,i|
    describe "#{File.basename(data_file)}##{i}" do
      # The `config` method is provided by
      # logstash-devutils/lib/logstash/devutils/rspec/logstash_helpers.rb.
      config(@@configuration)
      run_case(tcase, test_case['fields'], test_case['ignore'], data_file, i)
    end
  end
end
