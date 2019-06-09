# frozen_string_literal: true

require 'set'
require 'hash_digger'

# Utility class to map original Hash keys to the new ones
class HashRemapper
  # Current Library Version
  VERSION = '0.3.0'

  class << self
    # Remaps `data` Hash by renaming keys, creating new ones and
    # optionally aggregating values
    #
    # @example
    #   HashRemapper.remap(
    #     {a: 1, b: 2, c: 3},
    #     true
    #     a: :one,
    #     b: :two
    #   ) # => { one: 1, two: 2, c: 3 }
    #
    # @param [Hash] data the original Hash to remap
    # @param [Boolean] pass_trough the flag to pass the original key/value pairs (default: false)
    # @param [Hash] mapping the Hash which in the simplest case tells how to rename keys
    #
    # @return [Hash] remapped version of the original Hash
    #                (selected keys only or all the keys if we passed originals)
    def remap(data, pass_trough = false, mapping)
      mapping = pass_trough_mapping(data, mapping) if pass_trough

      mapping.each_with_object({}) do |(from, to), acc|
        key, value = try_callable(from, to, data, acc) ||
                     try_digging(to, data) ||
                     [to, data[from]]

        acc[key] = value
        acc
      end
    end

    private

    # Method to try to handle callable mapping Hash value
    # (if the mapping value is callable)
    #
    # @param [Object] from the source key to handle
    # @param [Object] to the target key to map to
    # @param [Hash] data the whole original Hash to use as the context in the lambda
    # @param [Hash] acc the accumulated result hash to check and merge existed data
    #
    # @return [Array(Object,Object)] key and its value to put to the resulting Hash
    def try_callable(from, to, data, acc)
      return unless to.respond_to?(:call)

      target_name, target_data = to.call(data[from], data)

      if acc.key?(target_name) && acc[target_name].respond_to?(:merge)
        target_data = acc[target_name].merge(target_data)
      end

      [target_name, target_data]
    end

    # Method to try to handle data digging
    # (if the mapping value is enumerable)
    # @see https://github.com/smileart/hash_digger
    #
    # @param [Array] to the target key to map to ([new_key, digging_path, strict_flag])
    # @param [Hash] data the whole original Hash to use as the digging target
    #
    # @return [Array(Object,Object)] key and its value to put to the resulting Hash
    def try_digging(to, data)
      return unless to.respond_to?(:each)

      digger_args = to.fetch(1)

      # v0.1.0 backward compartability layer ([new_key, [:digg, :path, :keys]])
      return [to.first, data.dig(*to.last)] if digger_args.kind_of?(Array)

      lambda = digger_args.fetch(:lambda) { nil }

      # @see https://github.com/DamirSvrtan/fasterer — fetch_with_argument_vs_block
      # @see https://github.com/smileart/hash_digger — digger args
      [
        to.fetch(0),
        HashDigger::Digger.dig(
          data: data,
          path: digger_args.fetch(:path) { '*' },
          strict: digger_args.fetch(:strict) { true },
          default: digger_args.fetch(:default) { nil },
          &lambda
        )
      ]
    end

    # Method which automatically prepares direct mapping (e.g. { :a => :a })
    # for the keys that weren't used in the mapping Hash (to pass them through "as is")
    #
    # @param [Hash] data the whole original Hash to take keys from
    # @param [Hash] mapping the mapping to use as the reference of the used keys
    #
    # @return [Hash] new mapping Hash containing original mapping + direct mappings
    def pass_trough_mapping(data, mapping)
      original_keys = Set.new(data.keys)
      mapping_keys  = Set.new(mapping.keys)

      pass_trough_keys    = original_keys.difference(mapping_keys)
      pass_trough_mapping = Hash[pass_trough_keys.zip(pass_trough_keys)]

      mapping.merge(pass_trough_mapping)
    end
  end
end
