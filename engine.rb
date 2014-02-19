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
    @low_tom = Surface.new(0, 100, 36)
    @high_tom = Surface.new(-100, 0, 38)
    @drums = [@low_tom, @high_tom]
    @@finger = nil
    @previous = {}
    super
  end

  def on_open(*args)
  end

  def on_frame(*args)
    frame = args[1]
    return if frame.nil?

    @@finger = frame.pointables.detect do |point|
      point.timeVisible > 1.5
    end

    if @@finger
      x_position = @@finger.tipPosition[0]
      y_position = @@finger.tipPosition[1]
      y_velocity = @@finger.tipVelocity[1]
      p y_velocity
    end

    return unless y_velocity
    return unless y_velocity.abs > 1000

    if is_a_hit?(frame.timestamp, y_velocity)
      drum_for(@drums, x_position)
    end

    @previous[:timestamp] = frame.timestamp
    @previous[:y_velocity] = y_velocity
  end

  def on_close(*args)
    puts args
  end

  private

  def is_a_hit?(timestamp, y_velocity)
    if @previous[:y_velocity] && y_velocity && @previous[:y_velocity] > 0 && y_velocity < 0 && (timestamp - @previous[:timestamp] > 500)
      puts "#{timestamp - @previous[:timestamp]} --- #{y_velocity}"
      #puts "#{timestamp}: #{@previous[:y_velocity]} --- #{y_velocity}"
      return true
    end
    false
  end

  def drum_for(drums, x_position)
    drum_hit = drums.select do |drum|
      x_position > drum.left_boundary && x_position < drum.right_boundary
    end.first

    drum_hit.play if drum_hit
  end
end

DrumSet.work!
