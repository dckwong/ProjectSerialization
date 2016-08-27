require 'yaml'

class Hangman
	attr_reader :word, :guesses
	def initialize
		@loaded = false
		@game_over = false
		@dictionary = set_up_dictionary 
		@word = get_random_word
		@answer_array = []
		@guesses = []
		@chances = 7
		set_up_answer_initially
		@player = Player.new
	end
	protected
	def loaded_true 
		@loaded = true
	end
	private
	def set_up_dictionary 
		dictionary = File.read("5desk.txt").split
		dictionary = dictionary.select do |word|
			word.length >= 5 && word.length <= 12
		end
		dictionary
	end


	def get_random_word 
		@dictionary.sample.downcase
	end

	def set_up_answer_initially 
		@word.length.times do 
			@answer_array << "_"
		end
		@answer_array
	end

	def check_guess_in_word
		guess = @player.guess
		chars = @word.chars
		if @word.include? guess
			chars.each.with_index do |letter,i|
				if letter == guess
					@answer_array[i] = letter
				end
			end
			return true
		else
			@chances -= 1
			return false
		end
	end

	def check_game_end
		if @answer_array == @word.chars
			@game_over = true
			puts "You got the word! The word was #{@word}"
		elsif @chances == 0
			@game_over = true
			puts "You didn't get the word! The word was #{@word}"
		end
	end
	public
	def display_answer
		puts "Your answer's so far: #{@answer_array.join(" ")}"
	end

	def display_guessed_letters
		puts "You've guessed so far: #{@guesses.join(", ")}"
	end


	private
	def display_chances_left
		puts "#{@chances} chances left!"
	end

	def save_game?
		if @player.get_user_save_or_load? 
			serialized_hangman = YAML::dump(self)
			File.open("saved_game #{Time.now.inspect}.sav",'w') { |f| f.write(serialized_hangman) }
			true
		else
			false
		end
	end

	public
	def play_game 
		prompt_user_for_load =  @player.get_user_save_or_load?(true) unless @loaded
		if prompt_user_for_load
			loaded_game = YAML.load(File.read(@player.get_save_file))
			loaded_game.loaded_true
			loaded_game.display_guessed_letters
			loaded_game.display_answer
			loaded_game.play_game
		else
			@player.get_user_guess
			@guesses << @player.guess
			until @game_over
				check_guess_in_word
				display_guessed_letters
				display_answer
				check_game_end 
				break if @game_over
				display_chances_left
				saved = save_game? 
				break if saved
				@player.get_user_guess
				@guesses << @player.guess

			end
		end
	end

end

class BadInput < StandardError; end
class DuplicateInput < StandardError; end

class Player
	attr_reader :guess
	def initialize 
		@guess = ""
		@guesses = []
	end

	public
	def get_user_guess 
		begin
			puts "Please type in a guess (one letter)!"
			guess = gets.chomp 
			raise BadInput if guess.length > 1 
			raise DuplicateInput if check_if_guessed(guess,@guesses)
		rescue BadInput
			puts "One letter only!"
			retry
		rescue DuplicateInput
			puts "You've already entered that!"
			retry
		else 
			@guesses << guess
			@guess = guess
		end
	end
	private
	def check_if_guessed guess, guesses
		guesses.include? guess
	end
	public
	def get_user_save_or_load? load=(false)
		begin 
			puts "Type 'yes' if you'd like to save the game for later and 'no' otherwise!" unless load
			puts "Type 'yes' if you'd like to load a save from before and 'no' otherwise!" if load
			input = gets.chomp
			raise BadInput if input != 'yes' && input != 'no'
		rescue BadInput
			retry
		else
			input == 'yes' ? true : false
		end
	end

	def get_save_file 
		begin
			puts "Choose from one of the following save files to load from"
			saves = Dir['*.sav']
			puts saves
			input = gets.chomp
			raise BadInput unless saves.include? input
		rescue BadInput
			puts "Not a valid file!"
			retry
		else
			input
		end
	end

end

game = Hangman.new
game.play_game()




