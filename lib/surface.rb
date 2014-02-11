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


