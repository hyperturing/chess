require './lib/board.rb'
require './lib/player.rb'

class Game
  attr_reader :board, :players, :winner

  def initialize(player1: 'Ashley', player2: 'Ashley-2.0', board: Board.new)
    instructions
    @board = board
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
    puts '(Ex: Bishop in the "c" rank moving to "h6" is: Bch6)'
    puts '=======NOTATION========'
    puts 'Pawn: p'
    puts 'Bishop: B'
    puts 'Rook: R'
    puts 'Knight: N'
    puts 'Queen: Q'
    puts 'King: K'
    puts
    puts '=======The Board========='
    puts
  end

  def play
    turn until over?

    if won?
      winner == :black || winner == :white
      puts "\nCongratulations #{@players[winner].name}! You won!!\n\n"
    elsif stalemate?
      puts 'Cats Game!'
    end
  end

  def turn
    @current_player = @board.current_player
    user_input = @players[@board.current_player].move
    until @board.valid_move?(user_input[0])
      puts 'Invalid move'
      user_input = @players[@board.current_player].move
    end
    @board.update(position: user_input[0], symbol: user_input[1])
    @winner = @current_player if won?
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
