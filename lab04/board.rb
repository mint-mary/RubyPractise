require_relative 'ship'
require_relative 'errors'

module Battleship
  class Board
    attr_reader :grid, :ships, :shots

    def initialize
      @shots = []
      place_ships
    end

    def display(hide_ships: false)
      puts "   1 2 3 4 5 6 7 8 9 10"
      @grid.each_with_index do |row, r_idx|
        row_str = "#{(r_idx + 65).chr}  "
        row.each do |cell|
          char = case cell
                 when :empty then "."
                 when :ship then hide_ships ? "." : "O"
                 when :hit then "X"
                 when :miss then "*"
                 end
          row_str += "#{char} "
        end
        puts row_str
      end
    end

    def shoot(r, c)
      raise OutOfBoundsError, "Координати за межами поля!" unless r.between?(0, 9) && c.between?(0, 9)
      raise RepeatedShotError, "Ви вже стріляли в цю клітинку!" if @shots.include?([r, c])

      @shots << [r, c]
      if @grid[r][c] == :ship
        @grid[r][c] = :hit
        ship = find_ship(r, c)
        ship.hit!([r, c])
        return ship.sunk? ? :sunk : :hit
      else
        @grid[r][c] = :miss
        return :miss
      end
    end

    def all_sunk?
      @ships.all?(&:sunk?)
    end

    private

    def find_ship(r, c)
      @ships.find { |s| s.coordinates.include?([r, c]) }
    end

    def place_ships
      sizes = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1]
      
      loop do
        @grid = Array.new(10) { Array.new(10, :empty) }
        @ships = []
        success = true

        sizes.each do |size|
          placed = false
          attempts = 0
          
          # Захист від нескінченного циклу при невдалому рандомі
          while !placed && attempts < 100
            r = rand(10)
            c = rand(10)
            horizontal = [true, false].sample
            
            coords = Array.new(size) { |i| horizontal ? [r, c + i] : [r + i, c] }

            if valid_placement?(coords)
              coords.each { |cr, cc| @grid[cr][cc] = :ship }
              @ships << Ship.new(coords)
              placed = true
            end
            attempts += 1
          end

          unless placed
            success = false
            break # Починаємо генерацію поля спочатку
          end
        end

        break if success
      end
    end

    def valid_placement?(coords)
      coords.each do |r, c|
        return false unless r.between?(0, 9) && c.between?(0, 9)
        
        # Перевірка сусідніх клітинок (включаючи діагоналі)
        (-1..1).each do |dr|
          (-1..1).each do |dc|
            nr, nc = r + dr, c + dc
            if nr.between?(0, 9) && nc.between?(0, 9)
              return false if @grid[nr][nc] == :ship
            end
          end
        end
      end
      true
    end
  end
end