require 'curses'

class Sketcher
  include Curses

  def initialize
    init_screen
    crmode
    curs_set(0)
    # draw drums?
  end

  def draw(hand)
    clear
    actual_height = hand.palmPosition[1]/10
    height = 50 - actual_height
    setpos(height + 1, 50)
    addstr("|")
    setpos(height, 50)
    addstr("*")
    setpos(height - 1, 50)
    addstr("|")
    refresh
  end

  def blam
    # I hit a drum!
  end
end
