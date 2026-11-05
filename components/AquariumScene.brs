' ---- Tweak these to taste ----
function config() as object
    return {
        fishCount: 9
        bubbleCount: 14
        fishImages: ["pkg:/images/fish1.png", "pkg:/images/fish2.png", "pkg:/images/fish3.png", "pkg:/images/fish4.png"]
    }
end function

sub init()
    m.top.backgroundColor = "0x0A3A60FF"
    cfg = config()
    fishLayer = m.top.findNode("fishLayer")
    for i = 0 to cfg.fishCount - 1
        addFish(fishLayer, cfg.fishImages[i mod cfg.fishImages.Count()], i)
    end for
    bubbleLayer = m.top.findNode("bubbleLayer")
    for i = 0 to cfg.bubbleCount - 1
        addBubble(bubbleLayer, i)
    end for
end sub

sub addFish(layer as object, uri as string, i as integer)
    scale = 0.5 + Rnd(0) * 0.7          ' 0.5x to 1.2x size
    w = Int(240 * scale) : h = Int(150 * scale)
    fish = layer.createChild("Poster")
    fish.id = "fish" + i.ToStr()
    fish.uri = uri
    fish.width = w : fish.height = h
    y = 80 + Rnd(760)
    bob = 30 + Rnd(50)

    goRight = (Rnd(2) = 1)
    if goRight
        xs = -w - 20 : xe = 1940
    else
        xs = 1940 : xe = -w - 20
        fish.scaleRotateCenter = [w / 2, h / 2]
        fish.scale = [-1, 1]             ' mirror so it faces left
    end if
    fish.translation = [xs, y]

    anim = layer.createChild("Animation")
    anim.duration = 14 + Rnd(20)         ' seconds to cross the screen
    anim.delay = Rnd(15)
    anim.repeat = true
    anim.easeFunction = "linear"
    interp = anim.createChild("Vector2DFieldInterpolator")
    interp.fieldToInterp = fish.id + ".translation"
    mid1 = xs + (xe - xs) * 0.33 : mid2 = xs + (xe - xs) * 0.66
    interp.key = [0.0, 0.33, 0.66, 1.0]
    interp.keyValue = [[xs, y], [mid1, y - bob], [mid2, y + bob], [xe, y]]
    anim.control = "start"
end sub

sub addBubble(layer as object, i as integer)
    size = 10 + Rnd(25)
    b = layer.createChild("Poster")
    b.id = "bubble" + i.ToStr()
    b.uri = "pkg:/images/bubble.png"
    b.width = size : b.height = size
    b.opacity = 0.7
    x = Rnd(1880)
    b.translation = [x, 1100]

    anim = layer.createChild("Animation")
    anim.duration = 6 + Rnd(8)
    anim.delay = Rnd(10)
    anim.repeat = true
    anim.easeFunction = "linear"
    interp = anim.createChild("Vector2DFieldInterpolator")
    interp.fieldToInterp = b.id + ".translation"
    interp.key = [0.0, 0.25, 0.5, 0.75, 1.0]
    interp.keyValue = [[x, 1100], [x + 15, 820], [x - 15, 540], [x + 15, 260], [x, -60]]
    anim.control = "start"
end sub
