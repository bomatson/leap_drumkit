class Surface
  attr_reader :left_boundary, :right_boundary, :drum_note

  SNARE_OPTIONS = { left: -51, right: 0, note: 38 }
  KICK_OPTIONS  = { left: 0, right: 200, note: 36 }
  HAT_OPTIONS   = { left: -200, right: -50, note: 57 }

  def initialize(drum_type=nil, *opts)
    case drum_type
    when :snare
      opts = SNARE_OPTIONS
    when :kick
      opts = KICK_OPTIONS
    when :hat
      opts = HAT_OPTIONS
    end

    unless opts.empty?
      @left_boundary = opts[:left]
      @right_boundary = opts[:right]
      @drum_note = opts[:note]
    end
  end

  def play(volume)
    output = UniMIDI::Output.open(:first)

    output.open do |node|
       node.puts(0x90, @drum_note, volume)
       sleep(0.1)
       node.puts(0x80, @drum_note, volume)
    end
  end
end
