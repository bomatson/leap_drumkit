## Building a LeapMotion DrumSet in Ruby

I love playing around with the LeapMotion. It is a wonderful little piece of technology, has great documentation, and is way ahead of its time.
More specifically, I'm interested in its potential to communicate with (MIDI)[http://en.wikipedia.org/wiki/MIDI], the protocol which allows software to translate musical data.

A quick aside: My background is in music, having played drums since I was a small fry. Naturally, my instinct was to make air-drumming possible with the LeapMotion.

I checked out the available options for LeapMotion "drumsets" and found them pretty difficult to use.
Nothing gave a valid attempt to properly interpret a stroke (aside from (AirDrum)[https://github.com/stocyr/AirDrum]), so I sought to build my own.

### Getting LeapMotion Sensor Data

The official LeapMotion API supports C++, C#, Java, Javascript and a few other languages. I wanted to use Ruby, so I hunted down a few suitable options.
To get up and running quickly, I used (Artoo's adapter for the LeapMotion)[https://github.com/hybridgroup/artoo-leapmotion].
If you haven't checked out the (Ruby on Robots)[http://artoo.io/] from (Hybrid Group)[http://hybridgroup.com/] yet, I would give it a look-see.

The LeapMotion sends data at each frame about every 'Pointable' it sees. A Pointable can be a finder or a tool (such as a drumstick or pen).
The Pointable has a X, Y and Z position, as well as the velocity in each direction. Check it out:

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

First off, major props to my teacher and good friend Giles Bowkett for helping me architect this!

We built a Surface class that could take a left and right boundary, as well as a drum note. The basic setup was hi-hat, snare and bass drum:

````ruby
class Surface
  #...

  SNARE_OPTIONS = { left: -51, right: 0, note: 38 }
  KICK_OPTIONS  = { left: 0, right: 100, note: 36 }
  HAT_OPTIONS   = { left: -100, right: -50, note: 57 }

  def initialize(drum_type=nil, *opts)
    case drum_type
    when :snare
      opts = SNARE_OPTIONS
    when :kick
      opts = KICK_OPTIONS
    when :hat
      opts = HAT_OPTIONS
    end

    if opts.present?
      @left_boundary = opts[:left]
      @right_boundary = opts[:right]
      @drum_note = opts[:note]
    end
  end

  #...

end
````

Next, we used the wonderful (UniMIDI)[https://github.com/arirusso/unimidi] library to communicate the surface sounds to MIDI.
UniMIDI lets you set the volume of each note, so we could play both soft & loud drum hits:

````ruby
def play(volume)
  output = UniMIDI::Output.open(:first)

  output.open do |node|
     node.puts(0x90, drum_note, volume)
     sleep(0.1)
     node.puts(0x80, drum_note, volume)
  end
end
````

Next, I built a DrumSet subclass of the Artoo::MainRobot which created the surfaces at initialization:

````ruby
class DrumSet < Artoo::MainRobot
  #...

  def initialize
    @bass_drum = Surface.new(:kick)
    @snare = Surface.new(:snare)
    @hi_hat = Surface.new(:hat)
    @drums = [@snare, @bass_drum, @hi_hat]

    #...
    super
  end
end
````

### Recognizing a Stroke

Once I had my surfaces in place, I needed to capture a single hand stroke.
At first, I attempted to read the velocity at each point in the stroke and determine the surface as a 'hit' once the Y velocity changed from positive to negative:

````ruby
def is_a_hit?(timestamp, y_velocity)
  if @previous[:y_velocity] && y_velocity && @previous[:y_velocity] > 0 && y_velocity < 0 && (timestamp - @previous[:timestamp] > 500)
    true
  end
  false
end
````

This attempt was a good first stab, but it became very complicated to read the velocity before and after a hit, as well as timestamp each frame of the stroke.

Also, I wanted to account for the dynamics of each hit. The velocity of the stroke is the key ingredient in determining how hard the drum is hit.
This could not be captured effectively if the velocity was always so close to 0.

The solution, thanks to some great help from (Alex Cruikshank)[http://www.carbonfive.com/employee/alex-cruikshank], was to create an imaginary threshold (say, 6 inches from the LeapMotion) and log the previous Y position of each stroke.
This way, a hit was only detected if the current Y position was less than the threshold, and the previous y_position was above it:

````ruby
def is_a_hit?(y_position)
  if @previous[:y_position] && @previous[:y_position] > 150 && y_position < 150
    true
  else
    false
  end
end
````

Next, I found the 'hit' surface in a `drum_for` method which compares the x_position to each drum's boundaries:

````ruby
def drum_for(x_position, y_velocity)
  determine_volume_from(y_velocity)

  drum_hit = @drums.detect do |drum|
    x_position > drum.left_boundary && x_position < drum.right_boundary
  end

  drum_hit.play(@volume) if drum_hit
end
````

I use the velocity at that point to calculate the 'loudness' of the stroke.
The MIDI protocol maxes out volume at 100, so the `determine_volume_from` function finds a proportional value between 0 - 100 based on the velocity:

````ruby
def determine_volume_from(velocity)
  @volume = [[ 0, (velocity.abs/30).to_i ].max, 100].min
end
````

### The Final Result

With this combination of techniques, I was able to detect a single stroke with a pretty reasonable amount of accuracy.
(Check it out for yourself!)[http://youtu.be/0CHaHR7FU6g]

### Next Moves!

The next challenge for this experiment is tracking the movements of both hands. Pointable objects have ids, but they are reset if the pointable ever goes out of range.
Luckily, the LeapMotion has a concept of a Hand object, where I can determine the X, Y and Z position of the palms. I gave this a shot in a (spike)[https://github.com/bomatson/leap_drumkit/tree/spike/explore-hands], but it is still quite a WIP

Now that I can track a stroke and trigger MIDI via the LeapMotion API, I'd also like to take a stab at rewriting this as a web app in Javascript.
With a but of visualization in the canvas, others will be able to access the drumkit from the browser!

If you'd like to keep track of the project's progress, you can view it on (Github)[https://github.com/bomatson/leap_drumkit]

I had a lot of fun doing this, and would encourage anyone to attempt playing around with the LeapMotion.
There's a lot of room for growth in the community, and it's always a little fun to live in the future.
