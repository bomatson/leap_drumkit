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
    @bass_drum = Surface.new(-49, -1, 38)
    @hit_hat = Surface.new(-100, -50, 57)
    @drums = [@snare, @bass_drum, @hit_hat]
    @@finger = nil
    @previous = {y_position: [] }
    super
  end

  def on_open(*args)
  end

  def cleanup
    @previous[:y_position] = []
  end

  def on_frame(*args)
    frame = args[1]

    cleanup if frame.hands.empty?
    #puts "hands: #{frame.hands.count}"

    #if frame.hands.length == 1
    frame.hands.each_with_index do |hand, index| 
      if is_a_hit?(hand, index)
        drum_for(@drums, hand.palmPosition[0], hand.palmVelocity[1])
      end
      @previous[:y_position][index] = hand.palmPosition[1] 
    end
    #@hand = frame.hands.first

    #x_position = @hand.palmPosition[0]
    #y_position = @hand.palmPosition[1]
    #y_velocity = @hand.palmVelocity[1]

    #if is_a_hit?(@hand, )
    #end

    #@previous[:y_position][:first] =  y_position
    #elsif frame.hands.length == 2
    #  @first_hand = frame.hands[0]
    #  @second_hand = frame.hands[1]


    #  #@active = [@first_hand, @second_hand].detect{ | hand| hand.palmPosition[1] < 150 }
    #  @active = nil

    #  [@first_hand, @second_hand].each_with_index do |hand, index|
    #    puts index
    #    if is_a_hit?(hand, index)
    #      @active = hand
    #    end
    #  end

    #  return if @active.nil?
    #  drum_for(@drums, @active.palmPosition[0], @active.palmVelocity[1])

    #  @previous[:y_position][:first] =  @first_hand.palmPosition[1]
    #  @previous[:y_position][:second] = @second_hand.palmPosition[1]
    #end
  end

  def on_close(*args)
    puts args
  end

  private

  def is_a_hit?(hand, index)
    #if index == 0
    #  key = :first
    #elsif index == 1
    #  key = :second
    #else
    #  return
    #end

    #puts key
    if @previous[:y_position][index] && hand.palmPosition[1] && @previous[:y_position][index] > 150 && hand.palmPosition[1] < 150
      puts "#{hand.palmPosition[1]} -- #{@previous[:y_position][index]}"
      true
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
