require_relative 'lib/surface'
require 'artoo'
require 'unimidi'

class DrumSet < Artoo::MainRobot
  connection :leapmotion, adaptor: :leapmotion, port: '127.0.0.1:6437'
  device :leapmotion, driver: :leapmotion

  work do
    on leapmotion, frame: :on_frame
    on leapmotion, close: :on_close
  end

  def initialize
    @bass_drum = Surface.new(:kick)
    @snare = Surface.new(:snare)
    @hi_hat = Surface.new(:hat)
    @drums = [@snare, @bass_drum, @hi_hat]

    @finger = nil
    @previous = {}
    super
  end

  def on_frame(*args)
    frame = args[1]

    return if frame.pointables.empty?

    set_finger_from(frame)

    if @finger
      x_position = @finger.tipPosition[0]
      y_position = @finger.tipPosition[1]
      y_velocity = @finger.tipVelocity[1]
    end

    puts "*" * (y_position/10).to_i

    if is_a_hit?(y_position)
      drum_for(x_position, y_velocity)
    end

    @previous[:y_position] = y_position
  end

  def on_close(*args)
    puts args
  end

  private

  def set_finger_from(frame)
    @finger = frame.pointables.reduce(nil) do |old, point|
      if old == nil || (point.tipPosition[1] < old.tipPosition[1]) && point.length > 40
        point
      else
        old
     end
    end
  end

  def is_a_hit?(y_position)
    if @previous[:y_position] && @previous[:y_position] > 150 && y_position < 150
      puts "#{y_position} -- #{@previous[:y_position]}"
      true
    else
      false
    end
  end

  def drum_for(x_position, y_velocity)

    drum_hit = @drums.detect do |drum|
      x_position > drum.left_boundary && x_position < drum.right_boundary
    end

    if drum_hit
      determine_volume_from(y_velocity)

      drum_hit.play(@volume)
    end
  end

  def determine_volume_from(velocity)
    @volume = [[ 0, (velocity.abs/30).to_i ].max, 100].min
  end
end

DrumSet.work!
