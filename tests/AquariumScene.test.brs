' Run by scene.test.js under @rokucommunity/brs, alongside components/AquariumScene.brs so config() is in scope.
' Animations never actually play here, so each "lap" is simulated by flipping the Animation's state.

function Main() as integer
    m.failures = 0
    m.cfg = config()
    m.laps = 40
    scene = CreateObject("roSGNode", "AquariumScene")
    if scene = invalid
        fail("AquariumScene could not be created")
        return m.failures
    end if

    testBuildsEveryFishAndBubble(scene)
    testFarFishDrawBehindNearFish(scene)
    testFishStayInTankEveryLap(scene)
    testBubblesRiseOffScreenEveryLap(scene)
    testBackgroundDriftNeverExposesEdge(scene)
    testClampFloat()

    print "AquariumScene suite: " + m.failures.ToStr() + " failure(s)"
    return m.failures
end function

sub testBuildsEveryFishAndBubble(scene as object)
    for i = 0 to m.cfg.fishCount - 1
        fish = scene.findNode("fish" + i.ToStr())
        anim = scene.findNode("fishAnim" + i.ToStr())
        if fish = invalid or anim = invalid
            fail("fish " + i.ToStr() + " or its animation is missing")
        else
            check(fish.uri = m.cfg.fishImages[i mod m.cfg.fishImages.Count()], "fish " + i.ToStr() + " uses the wrong image")
            check(anim.control = "start", "fish " + i.ToStr() + " animation was not started")
        end if
    end for
    check(scene.findNode("fish" + m.cfg.fishCount.ToStr()) = invalid, "more fish than fishCount")

    for i = 0 to m.cfg.bubbleCount - 1
        anim = scene.findNode("bubbleAnim" + i.ToStr())
        if scene.findNode("bubble" + i.ToStr()) = invalid or anim = invalid
            fail("bubble " + i.ToStr() + " or its animation is missing")
        else
            check(anim.control = "start", "bubble " + i.ToStr() + " animation was not started")
        end if
    end for
    check(scene.findNode("bubble" + m.cfg.bubbleCount.ToStr()) = invalid, "more bubbles than bubbleCount")
end sub

sub testFarFishDrawBehindNearFish(scene as object)
    for i = 1 to m.cfg.fishCount - 1
        prev = scene.findNode("fish" + (i - 1).ToStr())
        cur = scene.findNode("fish" + i.ToStr())
        check(cur.width >= prev.width, "fish " + i.ToStr() + " is smaller than the fish drawn behind it")
        check(cur.opacity >= prev.opacity, "fish " + i.ToStr() + " is fainter than the fish drawn behind it")
    end for
end sub

sub testFishStayInTankEveryLap(scene as object)
    for i = 0 to m.cfg.fishCount - 1
        fish = scene.findNode("fish" + i.ToStr())
        anim = scene.findNode("fishAnim" + i.ToStr())
        for lap = 0 to m.laps
            checkFishLap(fish, anim, "fish " + i.ToStr() + " lap " + lap.ToStr(), lap > 0)
            finishLap(anim)
        end for
    end for
end sub

sub checkFishLap(fish as object, anim as object, label as string, fromEdge as boolean)
    move = anim.getChild(0)
    tilt = anim.getChild(1)
    checkKeys(move.key, label + " move")
    checkKeys(tilt.key, label + " tilt")
    check(move.keyValue.Count() = move.key.Count(), label + ": move key/keyValue counts differ")
    check(tilt.keyValue.Count() = tilt.key.Count(), label + ": tilt key/keyValue counts differ")
    check(anim.duration > 0, label + ": non-positive duration")
    check(anim.delay >= 0 and anim.delay <= 8, label + ": delay out of range")

    w = fish.width : h = fish.height
    for each p in move.keyValue
        check(p[1] >= m.cfg.swimTop - 0.01, label + ": swims above swimTop (y=" + p[1].ToStr() + ")")
        check(p[1] + h <= m.cfg.sandLine + 0.01, label + ": swims into the sand (bottom=" + (p[1] + h).ToStr() + ")")
    end for
    for each t in tilt.keyValue
        check(Abs(t) <= 0.1401, label + ": tilt too steep (" + t.ToStr() + ")")
    end for

    first = move.keyValue[0]
    last = move.keyValue[move.keyValue.Count() - 1]
    check(fish.translation[0] = first[0] and fish.translation[1] = first[1], label + ": poster does not start at the first keyframe")
    if last[0] > first[0]
        check(fish.scale[0] = 1, label + ": swims right but faces left")
        check(last[0] >= 1920, label + ": stops before leaving the right edge")
        if fromEdge then check(first[0] + w <= 0, label + ": pops in on screen instead of from the left edge")
    else
        check(fish.scale[0] = -1, label + ": swims left but faces right")
        check(last[0] + w <= 0, label + ": stops before leaving the left edge")
        if fromEdge then check(first[0] >= 1920, label + ": pops in on screen instead of from the right edge")
    end if
end sub

sub testBubblesRiseOffScreenEveryLap(scene as object)
    for i = 0 to m.cfg.bubbleCount - 1
        bubble = scene.findNode("bubble" + i.ToStr())
        anim = scene.findNode("bubbleAnim" + i.ToStr())
        for lap = 0 to m.laps
            checkBubbleLap(bubble, anim, "bubble " + i.ToStr() + " lap " + lap.ToStr(), lap > 0)
            finishLap(anim)
        end for
    end for
end sub

sub checkBubbleLap(bubble as object, anim as object, label as string, fromBottom as boolean)
    interp = anim.getChild(0)
    checkKeys(interp.key, label)
    check(interp.keyValue.Count() = interp.key.Count(), label + ": key/keyValue counts differ")
    check(anim.duration > 0, label + ": non-positive duration")
    check(anim.delay >= 0 and anim.delay <= 4, label + ": delay out of range")
    check(bubble.width = bubble.height, label + ": not round")
    check(bubble.width >= 10 and bubble.width <= 35, label + ": size out of range")

    size = bubble.width
    for k = 0 to interp.keyValue.Count() - 1
        p = interp.keyValue[k]
        ' Wobble may nudge an edge bubble slightly past the screen edge
        check(p[0] >= -30 and p[0] + size <= 1950, label + ": drifts off the side of the screen")
        if k > 0 then check(p[1] < interp.keyValue[k - 1][1], label + ": sinks instead of rising")
    end for
    check(interp.keyValue[interp.keyValue.Count() - 1][1] + size <= 0, label + ": stops before leaving the top")
    if fromBottom then check(interp.keyValue[0][1] >= 1080, label + ": pops in on screen instead of from the bottom")
end sub

sub testBackgroundDriftNeverExposesEdge(scene as object)
    bg = scene.findNode("bg")
    drift = invalid
    for i = 0 to scene.getChildCount() - 1
        if scene.getChild(i).subtype() = "Animation" then drift = scene.getChild(i)
    end for
    if drift = invalid
        fail("background drift animation is missing")
        return
    end if

    check(drift.repeat, "background drift does not repeat")
    check(drift.control = "start", "background drift was not started")
    interp = drift.getChild(0)
    check(interp.fieldToInterp = "bg.translation", "background drift does not move bg")
    checkKeys(interp.key, "background drift")
    for each p in interp.keyValue
        check(p[0] <= 0.01 and p[1] <= 0.01, "background drift exposes the top/left edge")
        check(p[0] + bg.width >= 1919.99 and p[1] + bg.height >= 1079.99, "background drift exposes the bottom/right edge")
    end for
    first = interp.keyValue[0]
    last = interp.keyValue[interp.keyValue.Count() - 1]
    check(Abs(first[0] - last[0]) < 0.01 and Abs(first[1] - last[1]) < 0.01, "background drift jumps when it loops")
end sub

sub testClampFloat()
    check(clampFloat(-5, 0, 10) = 0, "clampFloat below range")
    check(clampFloat(15, 0, 10) = 10, "clampFloat above range")
    check(clampFloat(2.5, 0, 10) = 2.5, "clampFloat in range")
end sub

sub finishLap(anim as object)
    anim.state = "running"
    anim.state = "stopped"
end sub

sub checkKeys(keys as object, label as string)
    if keys.Count() < 2
        fail(label + ": fewer than two keyframes")
        return
    end if
    check(keys[0] = 0 and keys[keys.Count() - 1] = 1, label + ": keys do not span 0..1")
    for k = 1 to keys.Count() - 1
        check(keys[k] > keys[k - 1], label + ": keys are not increasing")
    end for
end sub

sub check(ok as boolean, msg as string)
    if not ok then fail(msg)
end sub

sub fail(msg as string)
    m.failures = m.failures + 1
    print "FAIL: " + msg
end sub
