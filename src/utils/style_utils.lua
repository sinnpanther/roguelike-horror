local StyleUtils = {}

function StyleUtils.newFont(size)
    return love.graphics.newFont(size or 16)
end

function StyleUtils.resetFont()
    love.graphics.setFont(StyleUtils.newFont())
end

function StyleUtils.resetColor()
    love.graphics.setColor(1, 1, 1, 1)
end

return StyleUtils
