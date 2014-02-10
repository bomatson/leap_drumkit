require 'artoo'
require 'unimidi'

class Surface < Struct.new(:left_boundary, :right_boundary, :drum_note)
  def play
    output = UniMIDI::Output.open(:first)

    output.open do |node|
       node.puts(0x90, drum_note, 100)
       sleep(0.1)
       node.puts(0x80, drum_note, 100)
    end
  end
end

connection :leapmotion, adaptor: :leapmotion, port: '127.0.0.1:6437'
device :leapmotion, driver: :leapmotion

work do
  on leapmotion, open: :on_open
  on leapmotion, frame: :on_frame
  on leapmotion, close: :on_close
end

def on_open(*args)
  puts args
end

def on_frame(*args)
  frame = args[1]
  finger = frame.pointables.sample

  if finger
    x_position = finger.tipPosition[0]
    y_position = finger.tipPosition[1]
    y_velocity = finger.tipVelocity[1]
  end

  if is_a_hit?(y_position) && y_velocity > 500

    drum_for(surfaces, x_position)

    p x_position
    p y_position
    p y_velocity
  end

end

def surfaces
  tom = Surface.new(0, 100, 30)
  snare = Surface.new(-100, 0, 47)

  drums = [snare, tom]
end

def drum_for(drums, x_position)
  drum_hit = drums.select do |drum|
    x_position > drum.left_boundary && x_position < drum.right_boundary
  end.first

  drum_hit.play if drum_hit
end

def on_close(*args)
  puts args
end

private

def is_a_hit?(y_position)
  y_position && y_position > 100 && y_position < 140
end

