## Building a LeapMotion DrumKit in Ruby

I love playing around with the LeapMotion. It is a wonderful little piece of technology, affordable, has great documentation, and is way ahead of its time.
More specifically, I'm interested in its potential to communicate with MIDI, the protocol which allows software to translate musical data.
I checked out the available options for LeampMotion "drumsets" and found them to be atrocious. Nothing even gave a valid attempt to properly interpret a single stroke, so I sought to build my own.

### Getting LeapMotion Sensor Data

LeapMotion Documentation mainly supports C++, C#, Java, Javascript and a few other languages. I wanted to use Ruby, so I hunted down a few suitable options.
To get up and running quickly, I used Artoo's adapter for the LeapMotion. If you haven't seen the Ruby on Robots libraries yet from Hybrid Group, I would give them a look-see.

The Leap sends data at each frame about every 'Pointable' it sees. A Pointable can be a tool (such as a drumstick) or even a finger.
The Pointable has a x, y and z position, as well as the velocity in each direction. Check it out:

````ruby
  def on_frame(*args)
    frame = args[1]

    return if frame.pointables.empty?

    set_finger_from(frame)

    if @finger
      x_position = @finger.tipPosition[0]
      y_position = @finger.tipPosition[1]
      y_velocity = @finger.tipVelocity[1]
    end

  #...

  end
````

### Creating Drum Surfaces

My next challenge was finding a way to create surfaces. First, I built a Surface struct that could take a left and right boundary, as well as note:
Then, I used the wonderful UniMidi library to communciate the surface sounds to MIDI:

````ruby
class Surface < Struct.new(:left_boundary, :right_boundary, :drum_note)
  def play(volume)
    output = UniMIDI::Output.open(:first)

    output.open do |node|
       node.puts(0x90, drum_note, volume)
       sleep(0.1)
       node.puts(0x80, drum_note, volume)
    end
  end
end
````

Next, I built a DrumKit class which created the surfaces at initialization:

````ruby
class DrumSet < Artoo::MainRobot
  #...

  def initialize
    @bass_drum = Surface.new(0, 100, 36)
    @snare = Surface.new(-51, 0, 38)
    @hi_hat = Surface.new(-100, -50, 57)
    @drums = [@snare, @bass_drum, @hi_hat]

    #...
    super
  end
end
````

### Recongizing a Stroke

Once I had my surfaces in place, I needed to capture a single hand stroke.
At first, I attempted to read the velocity at each point in the stroke and determine the surface as 'hit' once the Y velocity changed from positive to negative.

This attempt proved failure - it became very complicated to read the velocity before and after a hit, as well as timestamping the stroke so it didn not read more than one per stroke.
Also, I wanted to include dynamics in each stroke, which I could not capture when the velocity was essentially 0.

The solution, thanks to some great help from Alex @ Carbon Five, was to create an imaginary threshold (say, 6 inches from the Leap) and log the previous Y position of each stroke.
This way, I would only hit if the current Y position was below and the previous was above that threshold.

````ruby
  def is_a_hit?(y_position)
    if @previous[:y_position] && @previous[:y_position] > 150 && y_position < 150
      true
    else
      false
    end
  end
````

Next, I found the surface in a `drum_for` method which checked the X position to see which drum you had hit:

````ruby
  def drum_for(x_position, y_velocity)
    determine_volume_from(y_velocity)

    drum_hit = @drums.detect do |drum|
      x_position > drum.left_boundary && x_position < drum.right_boundary
    end

    drum_hit.play(@volume) if drum_hit
  end
````

The `determine_volume_from` function uses the velocity at that point the find a proptional value between 0 - 100, where 100 is the loudest.

````ruby
  @volume = [[ 0, (velocity.abs/30).to_i ].max, 100].min
````

Check out this video to see it in action: 

### An Attempt at Two Hands
