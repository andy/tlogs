module UserpicHelper
  def avatar_dimensions(user, options = {})
    avatar    = nil # user.avatar
    width     = avatar ? avatar.width : 64
    height    = avatar ? avatar.height : 64

    if (options[:width] && options[:width] < width) || (options[:height] && options[:height] < height)
      w_ratio = (options[:width] && options[:width] > 0) ? options[:width].to_f / width.to_f : 1
      h_ratio = (options[:height] && options[:height] > 0) ? options[:height].to_f / height.to_f : 1
    
      ratio = [w_ratio, h_ratio].min

      width = ratio < 1 ? (width * ratio).to_i : width
      height = ratio < 1 ? (height * ratio).to_i : height
    end
    
    OpenStruct.new :width => width, :height => height
  end

  def userpic_dimensions(user, options = {})
    return avatar_dimensions(user, options) unless user.userpic?
    
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
    
    OpenStruct.new :width => width, :height => height
  end
end