require 'artoo'

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
    x_position = finger.tipPosition[1]
    x_velocity = finger.tipVelocity[1]
  end

  if x_position > 100 && x_position < 140 && x_velocity > 500
    snare(finger)
    p x_position
    p x_velocity
  end
end

def snare(object)
  puts "snare drum"
end

def on_close(*args)
  puts args
end
