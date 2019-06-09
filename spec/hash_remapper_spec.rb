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
        test: ->(_, __) { [:test, 21] }
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

    it 'allows to use global context to create composite fields' do
      new_hash = HashRemapper.remap(
        original_hash,
        test: ->(data, context) { [:magic_number, data + context['data'][1]] }
      )

      expect(new_hash).to eq(magic_number: 44)
    end

    it 'merges values if the key already exists and supports #merge' do
      new_hash = HashRemapper.remap(
        original_hash,
        test: ->(_, __) { [:magic_number, { one: 1 }] },
        whatever: ->(_, __) { [:magic_number, { two: 2 }] }
      )

      expect(new_hash).to eq(magic_number: { one: 1, two: 2 })
    end

    it 'replaces values if the key already exists and doesn\'t support #merge' do
      new_hash = HashRemapper.remap(
        original_hash,
        test: ->(_, __) { [:magic_number, 42] },
        whatever: ->(_, __) { [:magic_number, 21] }
      )

      expect(new_hash).to eq(magic_number: 21)
    end

    it 'allows to assign static defaults through lambdas' do
      new_hash = HashRemapper.remap(
        original_hash,
        test: ->(_, __) { [:magic_number, 21] }
      )

      expect(new_hash).to eq(magic_number: 21)
    end

    it 'allows to remap to the deep values within the context' do
      new_hash = HashRemapper.remap(
        original_hash,
        test: [:magic_bool, {path: 'nested.really.deep'}]
      )

      expect(new_hash).to eq(magic_bool: true)
    end

    it 'allows to remap to the deep values recursively' do
      expect(HashRemapper.remap(
        original_hash,
        test: [:magic_numbers, {path: 'recursive.*.number', strict: false}]
      )).to eq(magic_numbers: [21, 42, nil])

      # test default path falling into "*"
      expect(HashRemapper.remap(
        original_hash,
        test: [:magic_numbers, {}]
      )).to eq(magic_numbers: original_hash.deep_symbolize_keys)

      expect {HashRemapper.remap(
        original_hash,
        test: [:magic_numbers, {path: 'recursive.*.number'}]
      )}.to raise_error(HashDigger::DigError)

      expect(HashRemapper.remap(
        original_hash,
        test: [:magic_numbers, {path: 'recursive.*.number', strict: false, default: 3.14}]
      )).to eq(magic_numbers: [21, 42, 3.14])

      expect(HashRemapper.remap(
        original_hash,
        test: [:magic_numbers, {path: 'recursive.*.number', strict: false, lambda: ->(result) { result.compact }}]
      )).to eq(magic_numbers: [21, 42])
    end

    it 'allows to use native digging from v0.1.0' do
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
  end
end
