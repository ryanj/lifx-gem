module LIFX
  # LIFX::Color represents a color intervally by HSBK (Hue, Saturation, Brightness/Value, Kelvin).
  # It has methods to construct a LIFX::Color instance from various color representations.
  class Color < Struct.new(:hue, :saturation, :brightness, :kelvin)
    UINT16_MAX = 65535
    DEFAULT_KELVIN = 3500
    KELVIN_MIN = 2500
    KELVIN_MAX = 10000

    class << self
      # Helper to create a white {Color}
      # @param brightness: [Float] Valid range: `0..1`
      # @param kelvin: [Integer] Valid range: `2500..10000`
      # @return [Color]
      def white(brightness: 1.0, kelvin: DEFAULT_KELVIN)
        new(0, 0, brightness, kelvin)
      end

      # Helper method to create from HSB/HSV
      # @param hue [Float] Valid range: `0..360`
      # @param saturation [Float] Valid range: `0..1`
      # @param brightness [Float] Valid range: `0..1`
      # @return [Color]
      def hsb(hue, saturation, brightness)
        new(hue, saturation, brightness, DEFAULT_KELVIN)
      end
      alias_method :hsv, :hsb

      # Helper method to create from HSBK/HSVK
      # @param hue [Float] Valid range: `0..360`
      # @param saturation [Float] Valid range: `0..1`
      # @param brightness [Float] Valid range: `0..1`
      # @param kelvin [Integer] Valid range: `2500..10000`
      # @return [Color]
      def hsbk(hue, saturation, brightness, kelvin)
        new(hue, saturation, brightness, kelvin)
      end

      # Helper method to create from HSL
      # @param hue [Float] Valid range: `0..360`
      # @param saturation [Float] Valid range: `0..1`
      # @param luminance [Float] Valid range: `0..1`
      # @return [Color]
      def hsl(hue, saturation, luminance)
        # From: http://ariya.blogspot.com.au/2008/07/converting-between-hsl-and-hsv.html
        l = luminance * 2
        saturation *= (l <= 1) ? l : 2 - l
        brightness = (l + saturation) / 2
        saturation = (2 * saturation) / (l + saturation)
        new(hue, saturation, brightness, DEFAULT_KELVIN)
      end

      def rgb(r, g, b)
        r = r / 255.0
        g = g / 255.0
        b = b / 255.0

        max = [r, g, b].max
        min = [r, g, b].min

        h = s = v = max
        d = max - min
        s = max.zero? ? 0 : d / max

        if max == min
          h = 0
        else
          case max
          when r
            h = (g - b) / d + (g < b ? 6 : 0)
          when g
            h = (b - r) / d + 2
          when b
            h = (r - g) / d + 4
          end
          h = h * 60
        end

        new(h, s, v, DEFAULT_KELVIN)
      end

      def from_struct(hsbk)
        new(
          (hsbk.hue.to_f / UINT16_MAX) * 360,
          (hsbk.saturation.to_f / UINT16_MAX),
          (hsbk.brightness.to_f / UINT16_MAX),
          hsbk.kelvin
        )
      end
    end

    def initialize(hue, saturation, brightness, kelvin)
      hue = hue % 360
      super(hue, saturation, brightness, kelvin)
    end

    # Returns a struct for use by the protocol
    # @api private
    # @return [Protocol::Light::Hsbk]
    def to_hsbk
      Protocol::Light::Hsbk.new(
        hue: (hue / 360.0 * UINT16_MAX).to_i,
        saturation: (saturation * UINT16_MAX).to_i,
        brightness: (brightness * UINT16_MAX).to_i,
        kelvin: [KELVIN_MIN, kelvin.to_i, KELVIN_MAX].sort[1]
      )
    end

    # Returns hue, saturation, brightness and kelvin in an array
    # @return [Array<Float, Float, Float, Integer>]
    def to_a
      [hue, saturation, brightness, kelvin]
    end

    EQUALITY_THRESHOLD = 0.001 # 0.1% variance
    # Checks if colours are equal to 0.1% variance
    # @param other [Color] Color to compare to
    # @return [Boolean]
    def ==(other)
      return false unless other.is_a?(Color)
      conditions = []
      conditions << ((hue - other.hue).abs < (EQUALITY_THRESHOLD * 360)) 
      conditions << ((saturation - other.saturation).abs < EQUALITY_THRESHOLD)
      conditions << ((brightness - other.brightness).abs < EQUALITY_THRESHOLD)
      conditions.all?
    end
  end
end
