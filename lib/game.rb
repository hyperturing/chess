require './board.rb'
require './player.rb'

class Game
  attr_reader :board, :players, :winner

  def initialize(player1: 'Ashley', player2: 'Ashley-2.0')
    instructions
    @board = Board.new

    @players = { white: Player.new(name: player1),
                 black: Player.new(name: player2) }
    @board.display_board
  end

  def instructions
    puts "Welcome to Chess ^.^  ^.^\n\n"
    puts 'Instructions:'
    puts '========================'
    puts 'To make a move when prompted:'
    puts 'Enter the chess notation of the move you wish to make'
    puts '(Ex: King at "a1" moving to "b2" is: Ka1-b2)'
    puts '=======NOTATION========'
    puts 'Pawn: p'
    puts 'Bishop: B'
    puts 'Rook: R'
    puts 'Knight: N'
    puts 'Queen: Q'
    puts 'King: K'
  end

  def play
    turn until over?

    if won?
      @winner == :black || @winner == :white
      puts "\nCongratulations #{@players[winner].name}! You won!!\n\n"
    elsif stalemate?
      puts 'Cats Game!'
    end
  end

  def turn
    current_player = @board.current_player
    user_input = @players[@board.current_player].move
    until @board.valid_move?(user_input)
      puts "Invalid move #{@board.hint}"
      user_input = @players[@board.current_player].move
    end
    @board.update(move: user_input)
    @winner = current_player if won?
    board.display_board
  end

  def over?
    !@board.legal_moves?
  end

  def won?
    over? && board.checkmate?
  end

  def stalemate?
    over? && !board.checkmate?
  end
end
