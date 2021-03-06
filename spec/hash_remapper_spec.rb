# frozen_string_literal: true

RSpec.describe HashRemapper do
  let(:original_hash) do
    {
      test: 42,
      'data' => [
        1,
        2,
        'string!'
      ],
      ignore: :me,
      nested: {
        hash: :data,
        really: {
          deep: true
        }
      },
      recursive: [
        { number: 21 },
        { number: 42 },
        { test: 13 }
      ]
    }
  end

  context 'within static method call' do
    it 'maps original keys to the new ones' do
      # Test shallow mapping
      new_hash = HashRemapper.remap(
        original_hash,
        test: :magic_number,
        'data' => :data,
        ignore: :dont_ignore,
        nested: :internal
      )

      expect(new_hash).to eq(
        magic_number: 42,
        data: [1, 2, 'string!'],
        dont_ignore: :me,
        internal: { hash: :data, really: { deep: true } }
      )

      # Test deep mapping
      new_hash = HashRemapper.remap(
        original_hash,
        test: :magic_number,
        'data' => :data,
        ignore: :dont_ignore,
        _: [[:internal, :secret, :private], :nested]
      )

      expect(new_hash).to eq(
        magic_number: 42,
        data: [1, 2, 'string!'],
        dont_ignore: :me,
        internal: { secret: { private: { hash: :data, really: { deep: true } } } }
      )
    end

    it 'auto-ignores all the skipped keys' do
      new_hash = HashRemapper.remap(
        original_hash,
        test: :magic_number
      )

      expect(new_hash).to eq(magic_number: 42)
    end

    it 'passes trough all the skipped keys if pass_trough == true' do
      new_hash = HashRemapper.remap(
        original_hash,
        true,
        test: :magic_number
      )

      expected_hash = {
        'data' => [1, 2, 'string!'],
        ignore: :me,
        magic_number: 42,
        nested: { hash: :data, really: { deep: true } },
        recursive: [{ number: 21 }, { number: 42 }, { test: 13 }]
      }

      expect(new_hash).to eq(expected_hash)
    end

    it 'preprocesses the value with a lambda' do
      new_hash = HashRemapper.remap(
        original_hash,
        _: ->(_, __) { [:test, 21] }
      )

      expect(new_hash).to eq(test: 21)
    end

    it 'allows remap keys within preprocessing' do
      new_hash = HashRemapper.remap(
        original_hash,
        test: ->(data, _) { [:magic_number, data.to_s] }
      )

      expect(new_hash).to eq(magic_number: '42')
    end

    it 'allows to keep data subsets only' do
      new_hash = HashRemapper.remap(
        original_hash,
        'data' => ->(data, _) { ['data', data[0..1]] }
      )

      expect(new_hash).to eq('data' => [1, 2])
    end

    it 'allows to include data with the original keynames' do
      new_hash = HashRemapper.remap(
        original_hash,
        test: :magic_number,
        ignore: :ignore
      )

      expect(new_hash).to eq(magic_number: 42, ignore: :me)
    end

    it 'allows to use global context (original hash) to create composite fields' do
      new_hash = HashRemapper.remap(
        original_hash,
        test: ->(data, context) { [:magic_number, data + context['data'][1]] }
      )

      expect(new_hash).to eq(magic_number: 44)
    end

    it 'merges values if the key already exists and supports #merge' do
      # test with a shallow target
      new_hash = HashRemapper.remap(
        original_hash,
        _: ->(_, __) { [:magic_number, { one: 1 }] },
        __: ->(_, __) { [:magic_number, { two: 2 }] }
      )

      expect(new_hash).to eq(magic_number: { one: 1, two: 2 })

      # test with a deep target
      new_hash = HashRemapper.remap(
        original_hash,
        _: ->(_, __) { [[:magic_number, :nested_key], { one: 1 }] },
        __: ->(_, __) { [[:magic_number, :nested_key], { two: 2 }] }
      )

      expect(new_hash).to eq(magic_number: { nested_key: { one: 1, two: 2 }})
    end

    it 'replaces values if the key already exists and doesn\'t support #merge' do
      new_hash = HashRemapper.remap(
        original_hash,
        _: ->(_, __) { [:magic_number, 42] },
        __: ->(_, __) { [:magic_number, 21] }
      )

      expect(new_hash).to eq(magic_number: 21)
    end

    it 'allows to assign static defaults through lambdas' do
      new_hash = HashRemapper.remap(
        original_hash,
        _: ->(_, __) { [:magic_number, 21] }
      )

      expect(new_hash).to eq(magic_number: 21)
    end

    it 'allows to remap to the deep values within the context' do
      new_hash = HashRemapper.remap(
        original_hash,
        _: [:magic_bool, {path: 'nested.really.deep'}]
      )

      expect(new_hash).to eq(magic_bool: true)
    end

    it 'allows to remap to the deep values recursively' do
      # test falling into default nil on unstrict digging
      expect(HashRemapper.remap(
        original_hash,
        _: [:magic_numbers, {path: 'recursive.*.number', strict: false}]
      )).to eq(magic_numbers: [21, 42, nil])

      # test default path falling into "*"
      expect(HashRemapper.remap(
        original_hash,
        _: [:magic_numbers, {}]
      )).to eq(magic_numbers: original_hash.deep_symbolize_keys)

      # test failing on wrong path with strict digging
      expect {HashRemapper.remap(
        original_hash,
        _: [:magic_numbers, {path: 'recursive.*.number'}]
      )}.to raise_error(HashDigger::DigError)

      # test falling into custom default on unstrict digging
      expect(HashRemapper.remap(
        original_hash,
        _: [:magic_numbers, {path: 'recursive.*.number', strict: false, default: 3.14}]
      )).to eq(magic_numbers: [21, 42, 3.14])

      # test handling the result with custom lambda
      expect(HashRemapper.remap(
        original_hash,
        _: [:magic_numbers, {path: 'recursive.*.number', strict: false, lambda: ->(result) { result.compact }}]
      )).to eq(magic_numbers: [21, 42])
    end

    it 'allows to use native digging from v0.1.0 for backward compartability' do
      new_hash = HashRemapper.remap(
        original_hash,
        test: [:magic_bool, %i[nested really deep]]
      )

      expect(new_hash).to eq(magic_bool: true)
    end

    it 'allows to create completely new keys' do
      new_hash = HashRemapper.remap(
        original_hash,
        test: :magic_number,
        absolutely_new_key: ->(_, __) { [:absolutely_new_key, 'shiny new value'] }
      )

      expect(new_hash).to eq(magic_number: 42, absolutely_new_key: 'shiny new value')
    end

    it 'allows to create nested target keys (mkdir-p-like behaviour)' do
      # test deep target from shallow source
      new_hash = HashRemapper.remap(
        original_hash,
        _: [[:nested, :new, :key], :test]
      )

      expect(new_hash).to eq({ nested: { new: { key: 42 } } })

      # test deep target from deep source (old digging API v0.1.0)
      new_hash = HashRemapper.remap(
        original_hash,
        _: [[:nested, :new, :key], [:nested,  :really, :deep]]
      )

      expect(new_hash).to eq({ nested: { new: { key: true } } })

      # test deep target from deep source (new digging API >= v0.2.0)
      new_hash = HashRemapper.remap(
        original_hash,
        _: [[:new, :deeply, :nested, :value], {path: 'recursive.*.number', strict: false, default: 3.14}]
      )

      expect(new_hash).to eq({ new: { deeply: { nested: { value: [21, 42, 3.14] } } } })
    end
  end
end
