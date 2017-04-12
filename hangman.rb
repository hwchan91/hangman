require "yaml"

class Hangman
  @@files = ["sav/save1.yml", "sav/save2.yml", "sav/save3.yml"]

  def initialize
    dictionary = File.read("5desk.txt").split(/\s+/)
    answer = ""
    until answer.length.between?(5,12)
      answer = dictionary[rand(dictionary.length)].upcase
    end
    @curr_game = NewGame.new(answer)
    @game_end = false
    run
  end

  class NewGame
    attr_accessor :answer_arr, :guessed_char

    def initialize(answer)
      @answer_arr = answer.split("")
      @guessed_char = []
    end
  end

  def run
    puts "-------New Game------"
    puts "Guess a word with #{@curr_game.answer_arr.length} characters."
    start_turn until @game_end == true
  end

  def start_turn
    display
    guessing_turn
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
    until ("A".."Z").include? guess and !@curr_game.guessed_char.include? guess
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

    puts "Confirm guess: '#{guess}'? (Y/N)"
    confirm = confirm_func("Confirm guess: '#{guess}'? (Y/N)")
    if confirm == "Y"
      @curr_game.guessed_char << guess
      check_guess(guess)
    else
      guessing_turn
    end
  end

  def confirm_func(text)
    confirm = ""
    until ["Y","N"].include? confirm
      confirm = gets.chomp.upcase
      if !["Y","N"].include? confirm
        puts "Invalid response. #{text}"
      end
    end
    confirm
  end


  def check_guess(guess)
    if @curr_game.answer_arr.all? {|char| @curr_game.guessed_char.include? char}
      puts "\nCONGRATULATIONS!!! You have guessed the answer #{@curr_game.answer_arr.join("")}"
      @game_end = true
    elsif (@curr_game.guessed_char - @curr_game.answer_arr).length >= 6
      puts "      GAME OVER\n\nThe answer is #{@curr_game.answer_arr.join("")}."
      @game_end = true
    else
      congratulatory_words = ["YES!", "Good job!", "Amazing!", "Fantastic!", "Absolutely!", "Nice!", "Wow!"]
      if @curr_game.answer_arr.include? guess
        puts "#{congratulatory_words[rand(congratulatory_words.length)]} The word has the letter '#{guess}'!"
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
  end

  def preload(a)
    @preload_close = false
    until @preload_close == true
      puts "-----SAVED GAMES------" if a == "save"
      puts "------LOAD GAMES------" if a == "load"
      @@files.each_with_index do |file_name, index|
        if File.exists? file_name
          preload_game = YAML.load(File.new(file_name, "r"))
          puts "#{index + 1}. #{word_display(preload_game)} (Misses: #{display_misses(preload_game)})"
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
          check_saves(response.to_i - 1) if a == "save"
          if a == "load"
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
      puts "Confirm overwrite file? (Y/N)"
      confirm = confirm_func("Confirm overwrite file? (Y/N)")
      if confirm == "Y"
        save_file(index)
      end
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
    @menu_close = true
  end

end

while true
  Hangman.new
end
