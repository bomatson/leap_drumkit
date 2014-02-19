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
    @snare = Surface.new(0, 100, 36)
    @bass_drum = Surface.new(-51, 0, 38)
    @hit_hat = Surface.new(-100, -50, 57)
    @drums = [@snare, @bass_drum, @hit_hat]
    @@finger = nil
    @previous = {}
    super
  end

  def on_open(*args)
  end

  def on_frame(*args)
    frame = args[1]
    return if frame.nil?

    #@@finger = frame.pointables.reduce(nil) { |old, point|
    #  if old == nil || (point.tipPosition[1] < old.tipPosition[1]) && point.length > 40
    #    p 'new'
    #    point
    #  else
    #    p 'OLD'
    #    old
    #  end
    #}

    @@finger = frame.pointables.detect do |point|
      p 'point'
      point.length > 40
    end

    if @@finger
      x_position = @@finger.tipPosition[0]
      y_position = @@finger.tipPosition[1]
      y_velocity = @@finger.tipVelocity[1]
    end

    #frame.pointables.delete(@@finger)

    #@@second_finger = frame.pointables.detect do |point|
    #  point.timeVisible > 0.5
    #end

    #if @@second_finger
     # p 'have a second'
     # byebug
    #end

    return unless y_velocity
    #return unless y_velocity.abs > 1000

    puts "*" * (y_position/10).to_i

    if is_a_hit?(frame.timestamp, y_position)
      drum_for(@drums, x_position, y_velocity)
    end
    @previous[:y_position] = y_position

    #@previous[:timestamp] = frame.timestamp
    #@previous[:y_velocity] = y_velocity
  end

  def on_close(*args)
    puts args
  end

  private

  #def is_a_hit?(timestamp, y_velocity)
  # if @previous[:y_velocity] && y_velocity && @previous[:y_velocity] > 0 && y_velocity < 0 && (timestamp - @previous[:timestamp] > 500)
    # puts "#{timestamp - @previous[:timestamp]} --- #{y_velocity}"
  #    puts "#{timestamp}: #{@previous[:y_velocity]} --- #{y_velocity}"
  #    return true
  #  end
  #  false
  #end

  def is_a_hit?(timestamp, y_position)
    if @previous[:y_position] && y_position && @previous[:y_position] > 150 && y_position < 150
      puts "#{y_position} -- #{@previous[:y_position]}"
      puts 'passed 200'
      return true
    else
      false
    end
  end

  def drum_for(drums, x_position, y_velocity)
    @volume = [[ 0, (y_velocity.abs/30).to_i ].max, 100].min
    drum_hit = drums.detect do |drum|
      x_position > drum.left_boundary && x_position < drum.right_boundary
    end
    drum_hit.play(@volume) if drum_hit
  end
end

DrumSet.work!
