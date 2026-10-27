module Battleship
  class BattleshipError < StandardError; end
  class OutOfBoundsError < BattleshipError; end
  class RepeatedShotError < BattleshipError; end
  class InvalidInputError < BattleshipError; end
end