require_relative 'lib/surface'
require_relative 'lib/sketcher'
require 'artoo'
require 'unimidi'

class DrumSet < Artoo::MainRobot
  connection :leapmotion, adaptor: :leapmotion, port: '127.0.0.1:6437'
  device :leapmotion, driver: :leapmotion

  work do
    on leapmotion, frame: :on_frame
  end

  def initialize
    @bass_drum = Surface.new(21, 140, 36)
    @snare = Surface.new(-49, 20, 38)
    # 33 is closed hat
    @crash = Surface.new(-100, -50, 57)
    @drums = [@snare, @bass_drum, @crash]
    @previous = {y_position: [] }
    @board = Sketcher.new
    super
  end

  def cleanup
    @previous[:y_position] = []
    return
  end

  def on_frame(*args)
    frame = args[1]

    cleanup if frame.hands.empty?

    frame.hands.each_with_index do |hand, index|

      @board.draw(hand)

      if is_a_hit?(hand, index)
        drum_for(@drums, hand.palmPosition[0], hand.palmVelocity[1])
      end
      @previous[:y_position][index] = hand.palmPosition[1]
    end
  end

  private

  def is_a_hit?(hand, index)
    if @previous[:y_position][index] && hand.palmPosition[1] && @previous[:y_position][index] > 150 && hand.palmPosition[1] < 150
      @board.blam

      # puts "OMFG A HIT #{hand.palmPosition[1]} -- #{@previous[:y_position][index]}"
      true
    else
      false
    end
  end

  def drum_for(drums, x_position, y_velocity)
    volume = [[ 0, (y_velocity.abs/30).to_i ].max, 100].min
    drum_hit = drums.detect do |drum|
      x_position > drum.left_boundary && x_position < drum.right_boundary
    end
    Thread.new do
      drum_hit.play(volume) if drum_hit
    end.join
  end
end

DrumSet.work!
