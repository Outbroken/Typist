--!strict

-->>--------------------------------------------<<--
-- @Created: September 27th, 2025
-- @Authors: Outbroken

-- @Description:
-- RGB Interpolator using OKLab
-- https://en.wikipedia.org/wiki/Oklab_color_space
-->>--------------------------------------------<<--

-- Converts an RGB value to a Linear RGB value
local function RGBToLinear(c: number): number
	if c <= 0.04045 then
		return c / 12.92
	else
		return ((c + 0.055) / 1.055) ^ 2.4
	end
end

-- Converts a Linear RGB value to an RGB value
local function linearToRGB(c: number): number
	if c <= 0.0031308 then
		return 12.92 * c
	else
		return 1.055 * c ^ (1 / 2.4) - 0.055
	end
end

-- Converts an RGB color (0-1) to an OKLab color
local function RGBToOKlab(r: number, g: number, b: number): (number, number, number)
	-- Linearize
	r = RGBToLinear(r)
	g = RGBToLinear(g)
	b = RGBToLinear(b)

	-- Convert to LMS
	local l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
	local m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
	local s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

	-- Cube root
	local l_ = l ^ (1 / 3)
	local m_ = m ^ (1 / 3)
	local s_ = s ^ (1 / 3)

	-- OKLab
	local L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
	local a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
	local b = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_

	return L, a, b
end

-- Converts an OKLab color to a Color3
local function OKLabToColor3(L: number, a: number, b: number): Color3
	local l_ = L + 0.3963377774 * a + 0.2158037573 * b
	local m_ = L - 0.1055613458 * a - 0.0638541728 * b
	local s_ = L - 0.0894841775 * a - 1.2914855480 * b

	-- Cube
	local l = l_ ^ 3
	local m = m_ ^ 3
	local s = s_ ^ 3

	-- LMS to linear RGB
	local r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
	local g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
	local b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

	-- De-linearize
	r = math.clamp(linearToRGB(r), 0, 1)
	g = math.clamp(linearToRGB(g), 0, 1)
	b = math.clamp(linearToRGB(b), 0, 1)

	return Color3.new(r, g, b)
end

-- Interpolator between two sRGB colors (r1,g1,b1) and (r2,g2,b2), t in [0, 1]
return function(rgb1: Color3, rgb2: Color3, t: number): Color3
	local L1, a1, b1_ = RGBToOKlab(rgb1.R, rgb1.G, rgb1.B)
	local L2, a2, b2_ = RGBToOKlab(rgb2.R, rgb2.G, rgb2.B)

	local L = L1 + (L2 - L1) * t
	local a = a1 + (a2 - a1) * t
	local b = b1_ + (b2_ - b1_) * t

	return OKLabToColor3(L, a, b)
end
