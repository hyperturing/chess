# frozen_string_literal: true
require 'matrix'
class Board
  attr_accessor :board, :current_player

  @@PIECES = %w[P B R N Q K]

  PIECES_BY_VALUE = { 'P' => 1, 'B' => 2, 'R' => 3,
                      'N' => 4, 'Q' => 5, 'K' => 6 }.freeze
  VALUES_BY_PIECE = { 0 => ' ', 1 => 'P', -1 => 'p',
                      2 => 'B', 3 => 'R', 4 => 'N',
                      5 => 'Q', 6 => 'K' }.freeze

  RANKS = %w[a b c d e f g h].freeze

  # Each piece has:
  #   'Slider' Pieces: A list of directions it can 'slide' to from it's current position
  #   'Leaper' Pieces: A list of offsets that it can 'leap' to from it's current position
  DELTAS =
    {
      'P' => [[2, 0], [1, 0]],
      'p' => [[-2, 0], [-1, 0]],
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
  COORDINATES_TO_NOTATION = {}
  HEIGHT.times do |row|
    RANKS.each_with_index do |rank, column|
      NOTATION_TO_COORDINATES[rank + (row + 1).to_s] = [row, column]
      COORDINATES_TO_NOTATION[[row, column]] = [rank + (row + 1).to_s]
    end
  end

  # Class methods:
  def self.notation_to_move(notation)
    piece_value = PIECES_BY_VALUE[notation[0]]
    start = NOTATION_TO_COORDINATES[notation[1..2]]
    finish = NOTATION_TO_COORDINATES[notation[4..5]]
    [start, finish, piece_value]
  end

  def self.move_to_notation(move)
    COORDINATES_TO_NOTATION[move]
  end

  # Instance Methods:
  #===================
  # Board initialization method:
  def initialize(fen_string: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')
    fen_components = fen_string.split(' ')
    fen_board = fen_components[0].split('/')
    @current_player = fen_components[1] == 'w' ? :white : :black

    # Keep a log of moves to allow for reversibility
    #   A move log is a 2-D array that contains move arrays
    #     The move array contains:
    #       Location to move from and the piece value that's moving
    #       Location to move to and the captured piece value
    @move_log = []

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

  # Board updater methods:
  ###########################
  def update(move:)
    # Parse components of move
    old_position = move[0]
    new_position = move[1]
    piece_value = @board[old_position[0]][old_position[1]]
    new_row, new_column = new_position[0], new_position[1]
    old_row, old_column = old_position[0], old_position[1]

    # Keep log of move with piece values for reversibility
    captured_piece_value = @board[new_row][new_column]
    move_from = [old_position, piece_value]
    move_to = [new_position, captured_piece_value]
    @move_log.push([move_from, move_to])

    # Moves piece to space, capturing piece occupying space
    # NOTE: Aside from undo or check?, this the only time we directly modify the board field
    # PLEASE DON'T modfy the board field unless you have a good reason
    @board[new_row][new_column] = piece_value
    @board[old_row][old_column] = 0

    # Promote pawn if it's reached the opposite side
    return unless piece_value.abs == 1 && [0, HEIGHT - 1].include?(new_row)

    @board[new_row][new_column] = PIECES_BY_VALUE['Q'] * piece_value
  end

  def undo
    # Reverts board changes performed by undo
    #  Uses our most recent move
    move = @move_log.pop

    move_from = move[0]
    move_to = move[1]

    old_position = move_from[0]
    piece_value = move_from[1]

    new_position = move_to[0]
    captured_piece_value = move_to[1]

    new_row, new_column = new_position[0], new_position[1]
    old_row, old_column = old_position[0], old_position[1]

    @board[new_row][new_column] = captured_piece_value
    @board[old_row][old_column] = piece_value
  end

  def next_player
    if @current_player == :white
      @current_player = :black 
    else
      @current_player = :white
    end
  end

  # Board read (i.e display or view) methods:
  ############################################
  def display_board
    puts "\n============The Board=============="
    puts '--------------Ranks----------------'
    puts '      ' + RANKS.join('   ')
    puts "-----------------------------------\n"
    puts
    output = @board.map.with_index do |row, index|
      [(index + 1).to_s + ' |', row.map do |value|
        value.abs != 1 ? VALUES_BY_PIECE[value.abs] : VALUES_BY_PIECE[value]
      end]
    end
    output.map { |element| puts element.join('   ') }
  end

  def hint(move)
    if empty_move?(move)
      "\nEmpty move!!"
    else
      old_position = move[0]
      piece_value = @board[old_position[0]][old_position[1]]
      return unless @board[old_position[0]][old_position[1]] == piece_value

      hint = "\nValid moves for #{VALUES_BY_PIECE[piece_value.abs]}: "
      hint + moves_for_piece(old_position).map { |move| Board.move_to_notation(move) }.join(' ')
    end
  end

  def all_legal_moves
    all_moves = moves_for_all_pieces(@current_player)
    allowed_moves = {}
    return all_moves unless check?

    # If the board is in check
    #   Iterate through each potential move for this piece
    #     Update the board with that move
    #     If the board is now in check
    #       Disallow the move
    #     'Undo' the board update
    all_moves.each_pair do |start_notation, finishes|
      start = NOTATION_TO_COORDINATES[start_notation]
      allowed_moves[start] = []
      finishes.each do |finish|
        update(move: [start, finish])
        allowed_moves[start].push(finish) unless check?
        undo
      end
    end
    allowed_moves
  end

  def moves_for_all_pieces(player)
    all_moves = NOTATION_TO_COORDINATES.inject({}) do |all_moves, (notation, position)|
      piece_value = @board[position[0]][position[1]]
      piece_sign = piece_value <=> 0.0
      player_sign = player == :white ? 1 : -1

      # We cannot move pieces that aren't ours
      if piece_value.zero? || piece_sign != player_sign
        moves = []
      else
        moves = moves_for_piece(position)
      end

      all_moves[notation] = moves
      all_moves
    end
    all_moves
  end

  def moves_for_piece(position)
    row = position[0]
    column = position[1]
    piece_value = @board[row][column]

    if [4, 6].include?(piece_value.abs)
      moves = leaper_moves(position)
    elsif [2, 3, 5].include?(piece_value.abs)
      moves = slider_moves(position)
    elsif piece_value.abs == 1
      moves = pawn_moves(position)
    else
      moves = []
    end

    # Filter out moves that capture the king
    return moves unless piece_value != PIECES_BY_VALUE['K']

    moves.reject do |move|
      @board[move[0]][move[1]] == PIECES_BY_VALUE['K']
    end
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

  # Boolean board status methods
  ##############################
  def valid_move?(move)
    return false if empty_move?(move)

    # Parse components of move
    old_position = move[0]
    new_position = move[1]

    piece_value = @board[old_position[0]][old_position[1]]

    return false if @board[old_position[0]][old_position[1]] != piece_value

    moves_for_piece(old_position).include?(new_position)
  end

  def empty_move?(move)
    move.all?(&:nil?)
  end

  def check?
    # Temporarily remove the king from our board
    #   This allows a piece to (potentially) capture the king's space
    attacking_player = @current_player == :white ? :black : :white
    king = @current_player == :white ? 6 : -6
    king_location = Matrix[*@board].index(king).to_a
    @board[king_location[0]][king_location[1]] = king.abs / king

    next_moves = moves_for_all_pieces(attacking_player)

    # Put the king back, please
    @board[king_location[0]][king_location[1]] = king

    !next_moves.select { |_, moves| moves.include?(king_location) }.empty?
  end

  def legal_moves?
    all_legal_moves.values.any? { |move| !move.empty? }
  end

  private

  def leaper_moves(position)
    # Returns an array of valid moves for a 'leaper' piece
    # (ie. Knight(4), King(6), pawn(1))
    #   Use the piece's move pattern
    #   and filter out moves that leave the board
    #   and moves that intersect with allied pieces
    row = position[0]
    column = position[1]
    piece_value = @board[row][column]

    piece_sign = piece_value <=> 0.0
    deltas_copy = deep_copy(DELTAS)
    if piece_value.abs != 1
      deltas = deltas_copy[VALUES_BY_PIECE[piece_value.abs]]
    else
      piece = VALUES_BY_PIECE[piece_value]
      deltas = deltas_copy[piece]
      deltas = [deltas[1]] if row != 1 && row != 6
    end

    moves = deltas.each do |delta|
      delta[0] += row
      delta[1] += column
    end

    moves = filter_moves(moves, piece_sign)
  end

  def slider_moves(position)
    # Returns an array of valid moves for a 'slider' piece
    # (Rook, Bishop, Queen)
    row = position[0]
    column = position[1]
    piece_value = @board[row][column]

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

      loop do
        current_move += delta_vector
        break if current_move.r >= WIDTH - 1 || current_move.r >= HEIGHT - 1 || @board[current_move[0]][current_move[1]].nonzero?

        moves.push(current_move.to_a)
      end

      if current_move.r <= WIDTH - 1 && current_move.r <= HEIGHT - 1 && (@board[current_move[0]][current_move[1]] <=> 0.0) != piece_sign
        moves.push(current_move.to_a)
      end
    end

    moves = filter_moves(moves, piece_sign)
  end

  def pawn_moves(position)
    row = position[0]
    column = position[1]
    piece_value = @board[row][column]
    piece_sign = piece_value <=> 0.0

    moves = leaper_moves(position)

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
          moves.push(black_corner)
        end
      end
    elsif piece_sign == 1
      white_corners.each do |white_corner|
        if (@board[white_corner[0]][white_corner[1]] <=> 0.0) != piece_sign && @board[white_corner[0]][white_corner[1]].nonzero?
          moves.push(white_corner)
        end
      end
    end

    moves = filter_moves(moves, piece_sign)
  end

  def deep_copy(object)
    Marshal.load(Marshal.dump(object))
  end
end
