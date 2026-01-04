local SoundManager = {}

SoundManager.sounds = {}

function SoundManager:load()
    self.sounds.glassSteps = {
        love.audio.newSource("assets/audio/sfx/footsteps/step_glass_01.wav", "static"),
    }

    self.sounds.normalStep =
    love.audio.newSource("assets/audio/sfx/footsteps/step_normal_01.wav", "static")
end

function SoundManager:playGlassStep(volume)
    local s = self.sounds.glassSteps[love.math.random(#self.sounds.glassSteps)]
    s:setVolume(volume or 0.6)
    s:stop()
    s:play()
end

function SoundManager:playNormalStep()
    local s = self.sounds.normalStep
    s:setVolume(0.4)
    s:stop()
    s:play()
end

return SoundManager
