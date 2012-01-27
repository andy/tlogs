module UserpicHelper
  def userpic_dimensions(user, options = {})
    if user.userpic?
      style     = \
        case options[:width] || 64
          when 0..16 then :thumb16
          when 16..32 then :thumb32
          when 32..64 then :thumb64
          when 64..128 then :thumb128
          else :thumb64
        end

      width     = user.userpic.width(style)
      height    = user.userpic.height(style)
    else
      width     = 0
      height    = 0
    end
    
    OpenStruct.new :width => width, :height => height
  end
end