module Battleship
  class Ship
    attr_reader :size, :coordinates, :hits

    def initialize(coordinates)
      @coordinates = coordinates
      @size = coordinates.length
      @hits = []
    end

    def hit!(coord)
      @hits << coord if @coordinates.include?(coord) && !@hits.include?(coord)
    end

    def sunk?
      @hits.length == @size
    end
  end
end