require_relative 'lib/surface'
require 'artoo'
require 'unimidi'
require 'byebug'

class DrumSet < Artoo::MainRobot
  connection :leapmotion, adaptor: :leapmotion, port: '127.0.0.1:6437'
  device :leapmotion, driver: :leapmotion

  work do
    on leapmotion, open: :on_open
    on leapmotion, frame: :on_frame
    on leapmotion, close: :on_close
  end

  def initialize
    @low_tom = Surface.new(0, 100, 20)
    @high_tom = Surface.new(-100, 0, 47)
    @@hit = true
    @drums = [@low_tom, @high_tom]
    super
  end

  def on_open(*args)
  end

  def on_frame(*args)
    frame = args[1]
    return if frame.nil?

    finger = frame.pointables.sample

    if @@hit && reset_hit?(finger)
      @@hit = false
    else
      @@hit = true
      return
    end

    if finger
      x_position = finger.tipPosition[0]
      y_position = finger.tipPosition[1]
      y_velocity = finger.tipVelocity[1]
    end

    if is_a_hit?(y_position) && @@hit == false
      drum_for(@drums, x_position)
      @@hit = true
    end
  end

  def on_close(*args)
    puts args
  end

  private

  def reset_hit?(finger)
    finger.nil? || finger.tipVelocity[1] < 0
  end

  def is_a_hit?(y_position)
    y_position && y_position > 100 && y_position < 125
  end

  def drum_for(drums, x_position)
    drum_hit = drums.select do |drum|
      x_position > drum.left_boundary && x_position < drum.right_boundary
    end.first

    drum_hit.play if drum_hit
  end
end

DrumSet.work!
