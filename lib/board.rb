# frozen_string_literal: true
require 'matrix'
class Board
  attr_accessor :board

  @@PIECES = %w[P B R N Q K]

  PIECES_BY_VALUE = { 'P' => 1, 'B' => 2, 'R' => 3,
                      'N' => 4, 'Q' => 5, 'K' => 6 }.freeze
  VALUES_BY_PIECE = { 1 => 'P', -1 => 'p', 2 => 'B', 3 => 'R',
                      4 => 'N', 5 => 'Q', 6 => 'K' }.freeze

  RANKS = %w[a b c d e f g h].freeze
  DELTAS =
    {
      'P' => [[1, 0]],
      'p' => [[-1, 0]],
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

  NOTATION_TO_COORDINATES = {}
  HEIGHT.times do |row|
    RANKS.each_with_index do |rank, column|
      NOTATION_TO_COORDINATES[rank + (row + 1).to_s] = [row, column]
    end
  end

  def self.notation_to_move(notation)
    piece_value = PIECES_BY_VALUE[notation[0]]
    start = NOTATION_TO_COORDINATES[notation[1..2]]
    finish = NOTATION_TO_COORDINATES[notation[4..5]]
    [start, finish, piece_value]
  end

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
            /[[:lower:]]/.match(space) ? PIECES_BY_VALUE[space.upcase] : -PIECES_BY_VALUE[space.upcase] 
          end
        end
      end
    end
  end

  def update(move:)
    # Parse components of move
    old_position = move[0]
    new_position = move[1]
    piece_value = move[2]

    new_row, new_column = new_position[0], new_position[1]
    old_row, old_column = old_position[0], old_position[1]

    # Moves piece to space, capturing piece occupying space
    @board[new_row][new_column] = piece_value
    @board[old_row][old_column] = 0

    return unless piece_value.abs == 1

    # Promote pawn if it's reached the opposite side
    return unless [0, HEIGHT - 1].include?(new_row)

    @board[new_row][new_column] = 5 * piece_value
  end

  def valid_move?(move)
    # Parse components of move
    old_position = move[0]
    new_position = move[1]
    piece_value = move[2]

    return false if @board[old_position[0]][old_position[1]] != piece_value

    legal_moves(old_position, piece_value).include?(new_position)
  end

  def display_board
    puts "\n=======The Board=============="
    output = @board.map { |row| row.map { |value| VALUES_BY_PIECE[value.abs] } }
    output.map { |element| puts element.join('   ') }
  end

  def hint(move)
    old_position = move[0]
    piece_value = move[2]
    return unless @board[old_position[0]][old_position[1]] == piece_value

    "Valid moves for #{VALUES_BY_PIECE[piece_value]}: #{legal_moves(old_position, piece_value)}"
  end

  def all_legal_moves
    all_moves = NOTATION_TO_COORDINATES.inject({}) do |all_moves, (notation, position)|
      piece_value = @board[position[0]][position[1]]

      if piece_value.zero?
        moves = []
      else
        moves = legal_moves(position, piece_value)
      end
      puts "Valid moves for #{notation}: #{moves}"
      all_moves[notation] = moves
      all_moves
    end
  end


  def legal_moves(position, piece_value)
    if [4, 6].include?(piece_value.abs)
      moves = leaper_legal_moves(position, piece_value)
    elsif [2, 3, 5].include?(piece_value.abs)
      moves = slider_legal_moves(position, piece_value)
    elsif piece_value.abs == 1
      moves = pawn_legal_moves(position, piece_value)
    else
      moves = []
    end

    # Filter out moves that capture the king
    return moves unless piece_value != PIECES_BY_VALUE['K']

    moves.reject do |move|
      @board[move[0]][move[1]] == PIECES_BY_VALUE['K']
    end
  end

  private

  def leaper_legal_moves(position, piece_value)
    # Returns an array of valid moves for a 'leaper' piece
    # (ie. Knight(4), King(6), pawn(1))
    #   Use the piece's move pattern
    #   and filter out moves that leave the board
    #   and moves that intersect with allied pieces
    row = position[0]
    column = position[1]

    piece_sign = piece_value <=> 0.0
    deltas_copy = deep_copy(DELTAS)
    if piece_value.abs != 1
      deltas = deltas_copy[VALUES_BY_PIECE[piece_value.abs]]
    else
      piece = VALUES_BY_PIECE[piece_value]
      deltas = deltas_copy[piece]
    end

    moves = deltas.each do |delta|
      delta[0] += row
      delta[1] += column
    end

    moves = filter_moves(moves, piece_sign)
  end

  def slider_legal_moves(position, piece_value)
    # Returns an array of valid moves for a 'slider' piece
    # (Rook, Bishop, Queen)

    piece_sign = piece_value <=> 0.0
    deltas_copy = deep_copy(DELTAS)
    deltas = deltas_copy[VALUES_BY_PIECE[piece_value.abs]]

    moves = []

    # For each directional 'delta'
    #   Proceed in that direction until we intersect another piece
    #     Pushing each move to our list of legal moves
    deltas.each do |delta|
      delta_vector = Vector.elements(delta)
      current_move = Vector.elements(position)

      until current_move.r > WIDTH - 1 || current_move.r > HEIGHT - 1 || @board[current_move[0]][current_move[1]].nonzero?
        moves.push(current_move.to_a)
        current_move += delta_vector
      end
      if (@board[current_move[0]][current_move[1]] <=> 0.0) != piece_sign
        moves.push(current_move.to_a)
      end
    end

    moves = filter_moves(moves, piece_sign)
  end

  def pawn_legal_moves(position, piece_value)
    row = position[0]
    column = position[1]
    piece_sign = piece_value <=> 0.0

    moves = leaper_legal_moves(position, piece_value)

    # Coordinates for each color's diagonals
    black_corners = [[row - 1, column + 1], [row - 1, column - 1]]
    white_corners = [[row + 1, column - 1], [row + 1, column + 1]]
    black_corners = filter_moves(black_corners, piece_sign)
    white_corners = filter_moves(white_corners, piece_sign)

    # Depending on if the piece is black/white
    #   Examine each diagonals in front on the pawn
    #     Add the diagonal if it's an opposing color

    if piece_sign == -1
      black_corners.each do |black_corner|
        if (@board[black_corner[0]][black_corner[1]] <=> 0.0) != piece_sign && @board[black_corner[0]][black_corner[1]].nonzero?
        #if (@board[black_corner[0]][black_corner[1]] <=> 0.0) != piece_sign
          moves.push(black_corner)
        end
      end
    elsif piece_sign == 1
      white_corners.each do |white_corner|
        if (@board[white_corner[0]][white_corner[1]] <=> 0.0) != piece_sign && @board[white_corner[0]][white_corner[1]].nonzero?
        #if (@board[white_corner[0]][white_corner[1]] <=> 0.0) != piece_sign
          moves.push(white_corner)
        end
      end
    end

    moves = filter_moves(moves, piece_sign)
  end

  def filter_moves(moves, piece_sign)
    # Filter out moves that leave the board
    #   or contain allied pieces
    moves.select do |move|
      (0..HEIGHT - 1).cover?(move[0]) &&
        (0..WIDTH - 1).cover?(move[1]) &&
        (@board[move[0]][move[1]] <=> 0.0) != piece_sign
    end
  end

  def deep_copy(o)
    Marshal.load(Marshal.dump(o))
  end
end

