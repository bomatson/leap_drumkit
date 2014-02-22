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

    return if frame.hands.empty?

    if frame.hands.length == 1
      @hand = frame.hands.first
      #@hand = frame.hands.detect{ |hand| hand.timeVisible > 0.5 }

      x_position = @hand.palmPosition[0]
      y_position = @hand.palmPosition[1]
      y_velocity = @hand.palmVelocity[1]
      print "\r"
      (y_position/10).to_i.times do
        print "*"
      end
      print "                                    "

      if is_a_hit?(y_position)
        drum_for(@drums, x_position, y_velocity)
      end

      @previous[:y_position] = y_position
    elsif frame.hands.length == 2
      @first_hand = frame.hands[0]
      @second_hand = frame.hands[1]

      @active = [@first_hand, @second_hand].detect{ | hand| hand.palmPosition[1] < 150 }
      return if @active.nil?
      p @active.id

      active_y_position = @active.palmPosition[1]

      if is_a_hit?(active_y_position)
        drum_for(@drums, @active.palmPosition[0], @active.palmVelocity[1])
      end

      @previous[:y_position] = active_y_position
    end
    #
    #if @hands.count == 1
    #  x_position[0] = @hands.first.palmPosition[0]
    #  y_position[0] = @hands.first.palmPosition[1]
    #  y_velocity[0] = @hands.first.palmVelocity[1]
    #  puts "*" * (y_position[0]/10).to_i
    #elsif @hands.count > 1
    #  @hands.each_with_index do |hand, index|
    #    x_position[index] = hand.palmPosition[0]
    #    y_position[index] = hand.palmPosition[1]
    #    y_velocity[index] = hand.palmPosition[1]
    #  end
    #  puts "X" * (y_position[1]/10).to_i
    #end


    #if @@hands.length == 1
    #elsif @@hands.length > 1
    #end


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

  def is_a_hit?(y_position)

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
