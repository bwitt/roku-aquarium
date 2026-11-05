' ---- Tweak these to taste ----
function config() as object
    return {
        fishCount: 9
        bubbleCount: 14
        fishImages: ["pkg:/images/fish1.png", "pkg:/images/fish2.png", "pkg:/images/fish3.png", "pkg:/images/fish4.png"]
        swimTop: 60         ' highest a fish's top edge may go
        sandLine: 930       ' fish bottoms stay above the sand in background.jpg
    }
end function

sub init()
    m.top.backgroundColor = "0x0A3A60FF"
    m.cfg = config()
    m.fish = {}
    m.bubbles = {}
    startBackgroundDrift()

    ' Far fish are created first so nearer fish draw on top of them
    depths = []
    for i = 0 to m.cfg.fishCount - 1
        depths.Push(Rnd(0))
    end for
    depths.Sort()
    fishLayer = m.top.findNode("fishLayer")
    for i = 0 to m.cfg.fishCount - 1
        addFish(fishLayer, m.cfg.fishImages[i mod m.cfg.fishImages.Count()], i, depths[i])
    end for

    bubbleLayer = m.top.findNode("bubbleLayer")
    for i = 0 to m.cfg.bubbleCount - 1
        addBubble(bubbleLayer, i)
    end for
end sub

' Slow pixel shift of the background to avoid burn-in on OLED TVs
sub startBackgroundDrift()
    anim = m.top.createChild("Animation")
    anim.duration = 300
    anim.repeat = true
    anim.easeFunction = "linear"
    interp = anim.createChild("Vector2DFieldInterpolator")
    interp.fieldToInterp = "bg.translation"
    keys = [] : values = []
    steps = 12
    for k = 0 to steps
        a = 2 * 3.14159265 * k / steps
        keys.Push(k / steps)
        values.Push([-30 + 30 * Cos(a), -17 + 17 * Sin(a)])
    end for
    interp.key = keys
    interp.keyValue = values
    anim.control = "start"
end sub

sub addFish(layer as object, uri as string, i as integer, depth as float)
    scale = 0.45 + depth * 0.75         ' 0.45x (far) to 1.2x (near)
    w = Int(240 * scale) : h = Int(150 * scale)
    fish = layer.createChild("Poster")
    fish.id = "fish" + i.ToStr()
    fish.uri = uri
    fish.width = w : fish.height = h
    fish.scaleRotateCenter = [w / 2, h / 2]
    fish.opacity = 0.55 + depth * 0.45  ' far fish fade into the water

    anim = layer.createChild("Animation")
    anim.id = "fishAnim" + i.ToStr()
    anim.easeFunction = "linear"
    move = anim.createChild("Vector2DFieldInterpolator")
    move.fieldToInterp = fish.id + ".translation"
    tilt = anim.createChild("FloatFieldInterpolator")
    tilt.fieldToInterp = fish.id + ".rotation"

    f = {poster: fish, anim: anim, move: move, tilt: tilt, w: w, h: h, depth: depth}
    m.fish[anim.id] = f
    anim.observeField("state", "onFishAnimState")
    ' Half the fish start mid-tank so the screen isn't empty at launch
    startSwim(f, i mod 2 = 0)
end sub

sub onFishAnimState(event as object)
    if event.getData() = "stopped" then startSwim(m.fish[event.getNode()], false)
end sub

' Picks a fresh random crossing each pass so no two laps look alike
sub startSwim(f as object, midTank as boolean)
    w = f.w : h = f.h
    bob = (10 + Rnd(0) * 30) * (0.5 + f.depth)
    yMin = m.cfg.swimTop + bob
    yMax = m.cfg.sandLine - h - bob
    y0 = yMin + Rnd(0) * (yMax - yMin)
    y1 = clampFloat(y0 + (Rnd(0) - 0.5) * 300, yMin, yMax)

    if Rnd(2) = 1
        xs = -w - 20 : xe = 1940
        f.poster.scale = [1, 1]
    else
        xs = 1940 : xe = -w - 20
        f.poster.scale = [-1, 1]        ' mirror so it faces left
    end if

    t0 = 0.0
    if midTank then t0 = 0.1 + Rnd(0) * 0.6
    cycles = 1 + Rnd(0) * 2.5
    phase = Rnd(0) * 2 * 3.14159265
    pxPerSec = (70 + Rnd(0) * 60) * (0.4 + f.depth)    ' near fish swim faster

    keys = [] : moves = [] : tilts = []
    steps = 24
    for k = 0 to steps
        t = t0 + (1 - t0) * k / steps
        a = phase + t * cycles * 2 * 3.14159265
        x = xs + (xe - xs) * t
        y = y0 + (y1 - y0) * t + bob * Sin(a)
        dydx = ((y1 - y0) + bob * Cos(a) * cycles * 2 * 3.14159265) / (xe - xs)
        keys.Push(k / steps)
        moves.Push([x, y])
        tilts.Push(clampFloat(Atn(-dydx) * 0.6, -0.14, 0.14))
    end for
    f.move.key = keys : f.move.keyValue = moves
    f.tilt.key = keys : f.tilt.keyValue = tilts
    f.poster.translation = moves[0]
    f.poster.rotation = tilts[0]

    f.anim.duration = Abs(xe - xs) * (1 - t0) / pxPerSec
    if midTank then f.anim.delay = 0 else f.anim.delay = Rnd(0) * 8
    f.anim.control = "start"
end sub

sub addBubble(layer as object, i as integer)
    b = layer.createChild("Poster")
    b.id = "bubble" + i.ToStr()
    b.uri = "pkg:/images/bubble.png"
    b.opacity = 0.7

    anim = layer.createChild("Animation")
    anim.id = "bubbleAnim" + i.ToStr()
    anim.easeFunction = "linear"
    interp = anim.createChild("Vector2DFieldInterpolator")
    interp.fieldToInterp = b.id + ".translation"

    bub = {poster: b, anim: anim, interp: interp}
    m.bubbles[anim.id] = bub
    anim.observeField("state", "onBubbleAnimState")
    startRise(bub, true)
end sub

sub onBubbleAnimState(event as object)
    if event.getData() = "stopped" then startRise(m.bubbles[event.getNode()], false)
end sub

sub startRise(bub as object, midTank as boolean)
    size = 10 + Rnd(25)
    bub.poster.width = size : bub.poster.height = size
    x = Rnd(1880)
    wobble = 8 + Rnd(0) * 14
    phase = Rnd(0) * 2 * 3.14159265
    t0 = 0.0
    if midTank then t0 = Rnd(0) * 0.8

    keys = [] : values = []
    steps = 12
    for k = 0 to steps
        t = t0 + (1 - t0) * k / steps
        keys.Push(k / steps)
        values.Push([x + wobble * Sin(phase + t * 4 * 3.14159265), 1100 - 1160 * t])
    end for
    bub.interp.key = keys : bub.interp.keyValue = values
    bub.poster.translation = values[0]

    bub.anim.duration = (6 + Rnd(0) * 8) * (1 - t0)
    if midTank then bub.anim.delay = 0 else bub.anim.delay = Rnd(0) * 4
    bub.anim.control = "start"
end sub

function clampFloat(v as float, lo as float, hi as float) as float
    if v < lo then return lo
    if v > hi then return hi
    return v
end function
