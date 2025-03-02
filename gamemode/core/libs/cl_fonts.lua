hook.Add("LoadFonts", "impulseLoadFonts", function()
    hook.Run("PreLoadFonts")

    surface.CreateFont("Impulse-CharacterInfo", {
        font = "Arial",
        size = 34,
        weight = 900,
        antialias = true,
        shadow = true,
        outline = true
    })

    surface.CreateFont("Impulse-CharacterInfo-NO", {
        font = "Arial",
        size = 34,
        weight = 900,
        antialias = true,
        shadow = true,
        outline = false
    })

    surface.CreateFont("Impulse-ChatSmall", {
        font = "Arial",
        size = 16,
        weight = 700,
        antialias = true,
        shadow = true,
    })

    surface.CreateFont("Impulse-ChatMedium", {
        font = "Arial",
        size = 17,
        weight = 700,
        antialias = true,
        shadow = true,
    })

    surface.CreateFont("Impulse-ChatRadio", {
        font = "Consolas",
        size = 17,
        weight = 500,
        antialias = true,
        shadow = true,
    })

    surface.CreateFont("Impulse-ChatLarge", {
        font = "Arial",
        size = 20,
        weight = 700,
        antialias = true,
        shadow = true,
    })

    surface.CreateFont("Impulse-UI-SmallFont", {
        font = "Arial",
        size = math.max(ScreenScale(6), 17),
        extended = true,
        weight = 500
    })

    surface.CreateFont("Impulse-SpecialFont", {
        font = "Arial",
        size = 33,
        weight = 3700,
        antialias = true,
        shadow = true
    })

    for i = 8, 80 do
        surface.CreateFont("Impulse-Elements" .. i, {
            font = "Arial",
            size = i,
            weight = 800,
            antialias = true,
            shadow = false,
        })

        surface.CreateFont("Impulse-Elements" .. i .. "-Shadow", {
            font = "Arial",
            size = i,
            weight = 800,
            antialias = true,
            shadow = true,
        })

        surface.CreateFont("Impulse-Elements" .. i .. "-Italic", {
            font = "Arial",
            size = i,
            weight = 800,
            italic = true,
            antialias = true,
            shadow = true,
        })
    end

    hook.Run("PostLoadFonts")
end)

hook.Add("OnScreenSizeChanged", "impulseReloadFonts", function()
    hook.Run("LoadFonts")
end)

hook.Add("OnSchemaLoaded", "impulseLoadFonts", function()
    hook.Run("LoadFonts")
end)