require "yaml"

class Dictionary
  @@dictionary = File.read("5desk.txt").split(/\s+/)
end

class Hangman < Dictionary
  @@files = ["sav/save1.yml", "sav/save2.yml", "sav/save3.yml"]

  def initialize
    vs = ""
    until ["1","2"].include? vs
      puts "Guess word: Enter 1; Choose word: Enter 2"
      vs = gets.chomp
      puts "Invalid response. Enter 1 or 2" if !["1","2"].include? vs
    end
    @curr_game = NewGame.new(vs)
    @game_end = false
    run
  end

  class NewGame < Dictionary
    attr_accessor :answer_arr, :guessed_char, :vs, :poss_words

    def initialize(vs)
      answer = ""
      until answer.length.between?(5,12)
        answer = @@dictionary[rand(@@dictionary.length)].upcase
      end

      @vs = vs
      @answer_arr = answer.split("") if vs == "1"
      @answer_arr = [] if vs == "2"
      @guessed_char = []
      @poss_words = []
    end
  end

  def run
    puts "-------New Game------"
    if @curr_game.vs == "1"
      puts "Guess a word with #{@curr_game.answer_arr.length} characters."
    else
      puts "Think of a secret word between 5-12 letters long."
      obtain_word_length
      @word_length.times { @curr_game.answer_arr.push ("") }
    end
    start_turn until @game_end == true
  end

  def start_turn
    display
    @curr_game.vs == "1"? guessing_turn : computer_guesses
  end

  def display
    hangman_ascii
    puts "WORD: #{word_display(@curr_game)}"
    puts "\nMisses: #{display_misses(@curr_game)}"
  end

  def hangman_ascii
    wrongs = (@curr_game.guessed_char - @curr_game.answer_arr).length
    puts %s{
       _________
       |        |}
    if wrongs >= 4
      puts "     \\ O /      |"
    elsif wrongs >= 3
      puts "     \\ O        |"
    elsif wrongs >= 1
      puts "       O        |"
    else
      puts "                |"
    end

    if wrongs >= 2
      puts "       |        |"
    else
      puts "                |"
    end

    if wrongs >= 6
      puts "      / \\       |"
    elsif wrongs >= 5
      puts "      /         |"
    else
      puts "                |"
    end
puts %s{                |
                |
   --------------
 }
  end

  def word_display(game)
    word_arr = game.answer_arr.map {|char| (game.guessed_char.include? char)? "#{char} " : %s{_ }}
    word_arr.join("")
  end

  def display_misses(game)
    (game.guessed_char - game.answer_arr).join(", ")
  end


  def guessing_turn
    guess = ""
    until (("A".."Z").include? guess and !@curr_game.guessed_char.include? guess) or @curr_game.vs == "2"
      puts "\nPlease guess a letter; or enter '0' for Menu"
      guess = gets.chomp.upcase

      if guess.length != 1 or (!("A".."Z").include? guess and guess != "0")
        puts "Invalid response. Please try again."
      elsif @curr_game.guessed_char.include? guess
        puts "Sorry, you have already guessed '#{guess}'."
      elsif guess == "0"
        menu
      end
    end

    if @curr_game.vs == "1"
      confirm = confirm_func("Confirm guess: '#{guess}'? (Y/N)")
      confirm == "Y"?  (@curr_game.guessed_char << guess; check_guess(guess)) : guessing_turn
    end
  end

  def confirm_func(text)
    confirm = ""
    puts text
    until ["Y","N"].include? confirm
      confirm = gets.chomp.upcase
      if !["Y","N"].include? confirm
        puts "Invalid response. #{text}"
      end
    end
    confirm
  end


  def check_guess(guess)
    @contain_word = false
    if @curr_game.answer_arr.all? {|char| @curr_game.guessed_char.include? char}
      puts "\nCONGRATULATIONS!!! You have guessed the word: '#{@curr_game.answer_arr.join("")}'"
      @game_end = true
    elsif (@curr_game.guessed_char - @curr_game.answer_arr).length >= 6
      puts "      GAME OVER\n\nThe answer is '#{@curr_game.answer_arr.join("")}'."
      @game_end = true
    else
      congratulatory_words = ["YES!", "Good job!", "Amazing!", "Fantastic!", "Absolutely!", "Nice!", "Wow!"]
      if @curr_game.answer_arr.include? guess
        puts "#{congratulatory_words[rand(congratulatory_words.length)]} The word has the letter '#{guess}'!"
        @contain_word = true
      else
        puts "Sorry! The word does not have the letter '#{guess}'!"
      end
    end
  end

  def menu
    response = ""
    @menu_close = false


    until ("1".."3").to_a.include? response and @menu_close == true
      puts %Q{
---------MENU---------
Choose an option below:
  1. Save game
  2. Load game
  3. Back
----------------------}
      response = gets.chomp
      if response == "1"
        preload("save")
      elsif response == "2"
        preload("load")
      elsif response == "3"
        @menu_close = true
      else
        puts "Invalid response. Please try again."
      end
    end
    display
    computer_guesses if @curr_game.vs == "2"
  end

  def preload(a)
    @preload_close = false
    until @preload_close == true
      puts "-----SAVED GAMES------" if a == "save"
      puts "------LOAD GAMES------" if a == "load"
      @@files.each_with_index do |file_name, index|
        if File.exists? file_name
          preload_game = YAML.load(File.new(file_name, "r"))
          puts "#{index + 1}. Player: #{preload_game.vs == "1"? "You" : "Computer"}; #{word_display(preload_game)} (Misses: #{display_misses(preload_game)})"
        else
          puts "#{index + 1}. Empty slot"
        end
      end
      puts "4. Back"
      puts "----------------------"

      response = ""
      until ["1","2","3","4"].include? response
        response = gets.chomp
        if ["1","2","3"].include? response
          if a == "save"
            check_saves(response.to_i - 1)
          else
            if File.exists? @@files[response.to_i - 1]
              load_file(response.to_i - 1)
              @preload_close = true
            else
              puts "Error! No file to load."
            end
          end
        elsif response == "4"
          @preload_close = true
        else
          puts "Invalid response. Please try again."
        end
      end
    end
  end

  def check_saves(index)
    Dir.mkdir("sav") unless Dir.exists? "sav"
    if File.exists? @@files[index]
      confirm = confirm_func("Confirm overwrite file? (Y/N)")
      save_file(index) if confirm == "Y"
    else
      save_file(index)
    end
  end

  def save_file(index)
    save_file = File.new(@@files[index], "w")
    save_file.puts YAML.dump(@curr_game)
    save_file.close
    puts "Game saved."
    @preload_close = true
    @menu_close = true
  end


  def load_file(index)
    @curr_game =  YAML.load(File.new(@@files[index], "r"))
    puts "Game loaded."
    p @curr_game.vs
    p @curr_game.poss_words
    p @curr_game.guessed_char
    p @curr_game.answer_arr
    @menu_close = true
  end

###
#COMPUTER AI

  def obtain_word_length
    begin
      puts "How many letters do your word have? (5-12)"
        response = gets.chomp
        response = Integer(response)
    rescue
      puts "Invalid response. Please try again."
      retry
    end

    if !(5..12).include? response
      puts "Sorry, but your word must between 5-12 letters long."
      puts "Please choose another word."
      obtain_word_length
    else
      @word_length = response
      poss_words = @@dictionary.select {|word| word.length == @word_length}
      @curr_game.poss_words = poss_words.map {|word| word.upcase}
    end
  end

  def computer_guesses
    letter_freq = Hash.new(0)
    ("A".."Z").to_a.each do |letter|
      @curr_game.poss_words.each do |word|
        letter_freq[letter] += 1 if word.include? letter
      end
    end
    letter_freq = letter_freq.sort_by {|a,b| b}.reverse

    i = 0
    @guess = ""
    while @curr_game.guessed_char.include? @guess or @guess == ""
      @guess = letter_freq[i][0]
      i += 1
    end

    puts "Computer selects #{@guess}"
    @curr_game.guessed_char << @guess
    computer_check_guess(@guess)
    reduce_poss_words if @curr_game.vs == "2"
  end


  def computer_check_guess(guess)
    puts "Does your word contain the letter '#{guess}'? (Y/N); or enter 0 for Menu."
    confirm1 = ""
    until ["Y","N"].include? confirm1 or @curr_game.vs == "1"
      confirm1 = gets.chomp.upcase
      if !["Y","N","0"].include? confirm1
        puts "Invalid response. Does your word contain the letter '#{guess}'? (Y/N); or enter 0 for Menu."
      elsif ["Y","N"].include? confirm1
        if confirm1 == "Y"
          text = "contains"
          t_or_f = true
        else
          text = "does not contain"
          t_or_f = false
        end
          double_confirm("Confirm: Are you sure your word #{text} the letter '#{guess}'? (Y/N)", t_or_f, confirm1, guess)
      else
        menu
      end
    end

  end

  def double_confirm(question, t_or_f, confirm1, guess)
    confirm2 = confirm_func(question)
    confirm2 == "Y"? (obtain_index if confirm1 == "Y"; @contain_word = t_or_f) : computer_check_guess(guess)
  end

  def display_letter_positions
    print "      "
    i = 1
    @word_length.times do
      print "#{i} "
      i += 1
    end
  end

  def obtain_index
    puts "Enter the position(s) in your word that has the letter '#{@guess}'."
    display_letter_positions
    puts "\nWORD: #{word_display(@curr_game)}"

    response = [100]
    until response.all? {|index| index.between?(1, @word_length) and @curr_game.answer_arr[index - 1] == ""}
      response = gets.chomp
      response = response.scan(/\d+/)
      response.map! {|i| i.to_i}
      if response == []
        puts "No position chosen. Please try again."
        response = [100]
      else
        response.each do |index|
          if !index.between?(1, @word_length)
            puts "#{index} is not a valid position."
          elsif @curr_game.answer_arr[index-1] != ""
            puts "Position #{index} is already taken!"
          end
        end
      end
    end

    cache = @curr_game.clone
    cache.answer_arr = @curr_game.answer_arr.clone
    cache.answer_arr = update_word_display(cache.answer_arr, response)

    display_letter_positions
    puts "\nWORD: #{word_display(cache)}"
    confirm = confirm_func("Confirm? (Y/N)")
    confirm == "Y"? (update_word_display(@curr_game.answer_arr, response); @indexes = response) : obtain_index

  end

  def update_word_display(arr, indexes)
    indexes.each do |index|
      arr[index-1] = @guess
    end
    arr
  end

  def reduce_poss_words
    if @contain_word == true
      @indexes.each do |i|
        @curr_game.poss_words = @curr_game.poss_words.select {|word| word[i-1] == @guess }
      end
      ((1..@word_length).to_a - @indexes.map{|i| i - 1 }).each do |i|
        @curr_game.poss_words = @curr_game.poss_words.select {|word| word[i] != @guess }
      end
    else
      @curr_game.poss_words = @curr_game.poss_words.select {|word| !word.include? @guess}
    end

    if @curr_game.poss_words.length <= 1
      if @curr_game.poss_words.length == 1 and @curr_game.answer_arr.any? {|letter| letter == ""}
        print "I know! "
        confirm = confirm_func("Is the word '#{@curr_game.poss_words[0]}'? (Y/N)")
        puts confirm == "Y"? "Yes! I knew it!!! Thank you for playing!" : "Sorry, I couldn\'t guess it."
      elsif @curr_game.poss_words.length == 0
        puts "Sorry, I couldn\'t guess it."
      elsif @curr_game.answer_arr.none? {|letter| letter == ""}
        puts "Yes! I knew it!!! Thank you for playing!"
      end
      @game_end = true
    end
  end

end


  Hangman.new
