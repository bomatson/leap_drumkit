class Surface < Struct.new(:left_boundary, :right_boundary, :drum_note)
  def play(volume)
    output = UniMIDI::Output.open(:first)

    output.open do |node|
       node.puts(0x90, drum_note, volume)
       #sleep(0.1)
       node.puts(0x80, drum_note, volume)
    end
  end
end


