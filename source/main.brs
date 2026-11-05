' Entry point Roku calls when the screensaver kicks in
sub RunScreenSaver()
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    screen.CreateScene("AquariumScene")
    screen.Show()
    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" and msg.IsScreenClosed() then return
    end while
end sub

' Lets you also launch it like an app from the home screen for testing
sub Main()
    RunScreenSaver()
end sub
