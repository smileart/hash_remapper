require 'hash_digger'
require 'hash_remapper'
require 'letters'

data = {
  :books => [
    {
      :title => "The Hitchhiker's Guide to the Galaxy",
      :editions => [
        {
          :isbn => "978-1-9936-7490-4",
          :language => "en",
          :pages => 193,
          :genres => [
            "comic",
            "science fiction"
          ]
        },
        {
          :isbn => "978-0-5762-2634-9",
          :language => "en",
          :pages => 208,
          :genres => [
            "comic",
            "fiction",
            "science fiction"
          ]
        },
        {
          :isbn => "978-5-4566-1998-3",
          :language => "de",
          :pages => 232,
          :genres => [
            "fiction",
            "science fiction"
          ]
        }
      ]
    },
    {
      :title => "To Kill a Mockingbird",
      :editions => [
        {
          :isbn => "978-4-0125-2865-3",
          :language => "en",
          :pages => 324,
          :genres => [
            "Southern Gothic",
            "Bildungsroman"
          ]
        },
        {
          :isbn => "978-5-3638-3280-2",
          :language => "en",
          :pages => 324,
          :genres => [
            "magic realism"
          ]
        }
      ]
    }
  ]
}

puts "Here we lose the relations between books and ISBNs:"
raw_result = HashRemapper.remap(
  data,
  titles: [:titles, { path: 'books.*.title' }],
  isbns: [:isbns, { path: 'books.*.editions.*.*.isbn' }]
).o

puts '='*50
puts

puts "Here we do a little trick splitting the path into two parts to presev relation in indexes"
isbn_result = HashRemapper.remap(
  data,
  titles: [:titles, { path: 'books.*.title' }],
  isbns: [:isbns, { path: 'books.*.editions.*', lambda: ->(editions) { editions.collect { |edition| HashDigger::Digger.dig(data: edition, path: '*.isbn') } } }]
).o

puts '='*50
puts

puts "Then we zip the data together in key => value format:"
Hash[isbn_result[:titles].zip(isbn_result[:isbns])].o

puts '='*50
puts ''

puts "Or create the new hashes assebling the data in any desirable structure:"
books_with_isbns = []
isbn_result[:titles].each_with_index do |t, i|
  books_with_isbns << {
    title: t,
    isbns: isbn_result[:isbns][i].uniq
  }
end

books_with_isbns.o
