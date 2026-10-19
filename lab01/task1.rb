class StringAnalyzer

    def word_stats()
        print "Print your string: "
        input_string = gets.chomp
        string_array = input_string.gsub( /[[:punct:]]/, "" ).split(" ")
        words_number = string_array.length
        longest_word = string_array.max_by{ |word| word.length }
        unique_count = string_array.uniq{|word|word.downcase}.length

        puts "Number of words: #{words_number}"
        puts "Longest word: #{longest_word}"
        puts "Number of unique words: #{unique_count}"
    end
end
        

StringAnalyzer.new.word_stats



