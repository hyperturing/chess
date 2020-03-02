# frozen_string_literal: true
require 'matrix'
class Board
  attr_reader :board

  PIECES_BY_VALUES = { 'P' => 1, 'B' => 2, 'R' => 3,
                       'N' => 4, 'Q' => 5, 'K' => 6 }.freeze
  VALUES_BY_PIECE = {1 => 'P', 2 => 'B', 3 => 'R',
                     4 => 'N', 5 => 'Q', 6 => 'K' }.freeze
  OFFSETS =
    {
      'P' => [[1, 0]],
      'B' => [[1, 1], [-1, -1], [1, -1], [-1, 1]],
      'R' => [[1, 0], [0, 1], [-1, 0], [0, -1]],
      'N' => [[2, -1], [1, -2], [1, 2], [2, 1],
              [-1, -2], [-2, -1], [-1, 2], [-2, 1]],
      'Q' => [[1, 0], [0, 1], [-1, 0], [0, -1],
              [1, 1], [-1, -1], [1, -1], [-1, 1]],
      'K' => [[1, 0], [0, 1], [-1, 0], [0, -1],
              [1, 1], [-1, -1], [1, -1], [-1, 1]]
    }.freeze
  WIDTH = 8
  HEIGHT = 8

  def initialize(fen_string: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')
    fen_components = fen_string.split(' ')
    fen_board = fen_components[0].split('/')
    @current_player = fen_components[1] == 'w' ? :white : :black

    @board = fen_board.map do |rank|
      if rank.match?(/^[[:digit:]]$/)
        Array.new(rank.to_i) { 0 }
      else
        rank.chars.map do |space|
          if space.match?(/^[[:alpha:]]$/)
            /[[:lower:]]/.match(space) ? PIECES_BY_VALUES[space.upcase] : -PIECES_BY_VALUES[space.upcase] 
          end
        end
      end
    end
  end

  def update(old_position:, new_position:, piece_value:)
    new_row, new_column = new_position[0], new_position[1]
    old_row, old_column = old_position[0], old_position[1]

    # Moves piece to space, capturing piece in space
    @board[new_row][new_column] = piece_value
    @board[old_row][old_column] = 0

    return unless piece_value.abs == 1

    # Promote pawn if it's reached the opposite side
    return unless [0, HEIGHT - 1].include?(new_row)

    @board[new_row][new_column] = 5 * piece_value
  end

  def display_board
    puts "\n=======The Board=============="
    output = @board.map { |row| row.map { |value| VALUES_BY_PIECE[value.abs] } }
    output.map { |element| puts element.join('   ') }
  end
end
