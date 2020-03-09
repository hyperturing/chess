require './board.rb'
class Player
  attr_accessor :name

  def initialize(name: 'Ashley')
    @name = name
  end

  def move
    puts "\n\n#{name}, please enter your move:"
    move_notation = gets.chomp
    Board.notation_to_move(move_notation)
  end
end
