require './lib/board.rb'
require './lib/player.rb'
require './lib/game.rb'

RSpec.describe Game do
  it 'creates a game board' do
    game = Game.new

    expect(game.board).to be_a Board
  end

  it 'creates a player1' do
    game = Game.new(black: 'Ashley', white: 'Ashley-2.0')

    expect(game.players[:black]).to be_a Player
  end

  it 'creates a player2' do
    game = Game.new(black: 'Ashley', white: 'Ashley-2.0')

    expect(game.players[:white]).to be_a Player
  end

  describe '#instructions' do
    it 'Displays a string of game instructions' do
      game = Game.new
      expect { game.instructions }.to output.to_stdout
    end
  end

  describe '#winner' do
    it 'returns the winner of the game' do
      game = game.new
      game.move(move: [5, 5], symbol: 1)
      game.move(move: [4, 3], symbol: -1)
      game.move(move: [6, 6], symbol: 1)
      game.move(move: [7, 4], symbol: -5)

      expect(game.winner).to eql(:black)
    end
  end

  describe '#won?' do
    it 'returns true if there is a winner' do
      game = Game.new
      game.move(move: [5, 5], symbol: 1)
      game.move(move: [4, 3], symbol: -1)
      game.move(move: [6, 6], symbol: 1)
      game.move(move: [7, 4], symbol: -5)

      expect(game.won?).to eql(true)
    end

    it 'returns false if there is no winner yet' do
      game = Game.new
      game.move(move: [5, 5], symbol: 1)
      game.move(move: [4, 3], symbol: -1)
      game.move(move: [6, 6], symbol: 1)

      expect(game.won?).to eql(false)
    end
  end

  describe '#turn' do
    it 'gets valid move from player and places symbol on board' do
      game = Game.new
      IoTestHelpers.simulate_stdin('a2 a3') { game.turn }
      expect(game.board.board[0][5].symbol).to eql(1)
    end
  end
end
