extends Node

static func generate(size = 128):
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx = size / 2
	var cy = size / 2
	var r = size / 2 - 2

	for y in range(size):
		for x in range(size):
			var dx = x - cx
			var dy = y - cy
			var dist = sqrt(dx * dx + dy * dy)
			if dist > r:
				continue
			var angle = atan2(dy, dx)
			var edge = dist / r
			var spiral = cos(angle * 4.0 + dist * 0.25) * 0.5 + 0.5
			var bright = (1.0 - edge * 0.7) * (0.2 + 0.8 * spiral)
			var red = Color(0.65 * bright, 0.02 * bright, 0.02 * bright)
			var dark = Color(0.05, 0.0, 0.0, 0.95)
			var col = red.lerp(dark, edge * 0.6)
			col.a = 0.7 + 0.3 * (1.0 - edge)
			img.set_pixel(x, y, col)

	for y in range(size):
		for x in range(size):
			var dx = x - cx
			var dy = y - cy
			var dist = sqrt(dx * dx + dy * dy)
			if dist > r - 2:
				continue
			var angle = atan2(dy, dx)
			var ring_r = r * 0.6
			var ring_w = 3.0
			if absf(dist - ring_r) < ring_w:
				var t = 1.0 - absf(dist - ring_r) / ring_w
				var pat = t * (0.5 + 0.5 * sin(angle * 6.0 + dist * 0.5))
				if pat > 0.3:
					var blood = Color(1.0, 0.15, 0.05, pat * 0.8)
					var existing = img.get_pixel(x, y)
					img.set_pixel(x, y, blood.blend(existing))

	for y in range(size):
		for x in range(size):
			var dx = x - cx
			var dy = y - cy
			var dist = sqrt(dx * dx + dy * dy)
			if dist > r - 1 or dist < r * 0.15:
				continue
			var angle = atan2(dy, dx)
			for k in range(5):
				var a = float(k) * TAU / 5.0 + 0.6
				var mid_a = a + TAU / 10.0
				var crystal_r = r * (0.6 + 0.3 * sin(k * 2.5 + dist * 0.1))
				var w = 4.0
				var angle_diff = absf(wrapf(angle - mid_a, -PI, PI))
				var crystal_dist = absf(dist - crystal_r)
				if angle_diff < w / crystal_r and crystal_dist < 5.0:
					var t_a = 1.0 - angle_diff * crystal_r / w
					var t_r = 1.0 - crystal_dist / 5.0
					var bright2 = t_a * t_r
					var blood_shard = Color(1.0, 0.15, 0.05, bright2 * 0.9)
					var existing = img.get_pixel(x, y)
					img.set_pixel(x, y, blood_shard.blend(existing))

	for y in range(-1, 2):
		for x in range(-1, 2):
			var px = cx + x * 2
			var py = cy + y * 2
			if px >= 0 and px < size and py >= 0 and py < size:
				var core = Color(1.0, 0.1, 0.04, 0.95)
				var existing = img.get_pixel(px, py)
				img.set_pixel(px, py, core.blend(existing))

	return ImageTexture.create_from_image(img)
