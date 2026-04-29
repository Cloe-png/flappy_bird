-- Rendu de l'interface et des écrans.
-- Lis ce fichier comme ca :
-- 1. outils de dessin
-- 2. rendu de la partie
-- 3. menus
-- 4. boutique
-- 5. game over

-- -------------------------------------------------------------------
-- OUTILS DE RENDU
-- -------------------------------------------------------------------

-- Traduit une clé de difficulté en texte lisible.
function getDifficultyLabel(mode)
    for i = 1, #difficultyOptions do
        if difficultyOptions[i].key == mode then
            return difficultyOptions[i].label
        end
    end

    return "Moyen"
end

-- Dessine un panneau réutilisable pour les menus et overlays.
function drawSoftPanel(x, y, w, h, borderColor)
    love.graphics.setColor(0, 0, 0, 0.22)
    love.graphics.rectangle("fill", x + 5, y + 6, w, h, 18, 18)
    love.graphics.setColor(0.08, 0.10, 0.16, 0.82)
    love.graphics.rectangle("fill", x, y, w, h, 18, 18)
    love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
    love.graphics.rectangle("line", x, y, w, h, 18, 18)
end

-- Petit helper pour dessiner une frame de sprite.
function drawSprite(image, quad, x, y, rotation, scaleX, scaleY, ox, oy)
    love.graphics.setColor(1, 1, 1)
    if quad ~= nil then
        love.graphics.draw(image, quad, x, y, rotation, scaleX, scaleY, ox, oy)
    else
        love.graphics.draw(image, x, y, rotation, scaleX, scaleY, ox, oy)
    end
end

-- Dessine un tuyau dans le bon sens sans le retourner.
function drawPipeUpright(image, data, x, y, width, height)
    if image == nil or data == nil or height <= 0 then
        return
    end

    local capHeight = data.capHeight
    local bodyHeight = math.max(0, height - capHeight)
    local scaleX = width / data.width
    local capScaleY = capHeight > 0 and (capHeight / data.capHeight) or 1
    local bodyScaleY = data.bodyHeight > 0 and (bodyHeight / data.bodyHeight) or 1

    love.graphics.draw(image, data.capQuad, x, y, 0, scaleX, capScaleY)

    if bodyHeight > 0 then
        love.graphics.draw(image, data.bodyQuad, x, y + capHeight, 0, scaleX, bodyScaleY)
    end
end

-- Dessine un tuyau en haut ou en bas.
function drawPipe(image, data, x, y, width, height, flipped)
    if flipped then
        love.graphics.push()
        love.graphics.translate(0, y + height)
        love.graphics.scale(1, -1)
        drawPipeUpright(image, data, x, 0, width, height)
        love.graphics.pop()
    else
        drawPipeUpright(image, data, x, y, width, height)
    end
end

-- Ajoute un contour noir pour que les tuyaux ressortent mieux.
function drawPipeWithOutline(image, data, x, y, width, height, flipped)
    love.graphics.setColor(0, 0, 0, 1)
    drawPipe(image, data, x - 1, y, width, height, flipped)
    drawPipe(image, data, x + 1, y, width, height, flipped)
    drawPipe(image, data, x, y - 1, width, height, flipped)
    drawPipe(image, data, x, y + 1, width, height, flipped)

    love.graphics.setColor(1, 1, 1, 1)
    drawPipe(image, data, x, y, width, height, flipped)
end

-- -------------------------------------------------------------------
-- PREVIEWS DE BOUTIQUE
-- -------------------------------------------------------------------

function getBirdScaleMultiplier(index, isPreview)
    local skin = birdSkins[index]
    if skin == nil then
        return 1
    end

    if isPreview then
        return skin.previewScale or skin.drawScale or 1
    end

    return skin.drawScale or 1
end

function drawBirdPreview(index, x, y, scaleMultiplier)
    local image, quad, frameWidth, frameHeight = getBirdSpriteVisual(index)
    local previewScaleMultiplier = scaleMultiplier or 1

    if image ~= nil then
        local scale = math.min(44 / frameWidth, 32 / frameHeight) * getBirdScaleMultiplier(index, true) * previewScaleMultiplier
        drawSprite(image, quad, x + 22 * previewScaleMultiplier, y + 16 * previewScaleMultiplier, 0, scale, scale, frameWidth / 2, frameHeight / 2)
        return
    end

    love.graphics.setColor(1, 0.82, 0.18)
    love.graphics.rectangle("fill", x, y, 44 * previewScaleMultiplier, 32 * previewScaleMultiplier)
end

function drawBackgroundPreview(index, x, y, w, h)
    local image = backgroundSprites[index]

    if image ~= nil then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(image, x, y, 0, w / image:getWidth(), h / image:getHeight())
        return
    end

    love.graphics.setColor(0.45, 0.76, 1)
    love.graphics.rectangle("fill", x, y, w, h)
end

function drawPipePreview(index, x, y, scaleMultiplier)
    local image, data = getPipeSpriteVisual(index)
    if image == nil or data == nil then
        return
    end

    local previewScaleMultiplier = scaleMultiplier or 1

    drawPipeWithOutline(image, data, x + 8 * previewScaleMultiplier, y, 24 * previewScaleMultiplier, 70 * previewScaleMultiplier, true)
    drawPipeWithOutline(image, data, x + 40 * previewScaleMultiplier, y + 30 * previewScaleMultiplier, 24 * previewScaleMultiplier, 70 * previewScaleMultiplier, false)
end

-- -------------------------------------------------------------------
-- RENDU DE LA PARTIE
-- -------------------------------------------------------------------

-- Dessine le fond puis le sol.
function drawBackground()
    -- On affiche d'abord le décor choisi.
    local activeBackgroundIndex = getActiveBackgroundIndex()
    local image = backgroundSprites[activeBackgroundIndex]

    if image ~= nil then
        love.graphics.clear(0.42, 0.75, 0.98)
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(image, 0, 0, 0, WINDOW_WIDTH / image:getWidth(), GROUND_Y / image:getHeight())
    else
        love.graphics.clear(0.42, 0.75, 0.98)
    end

    love.graphics.setColor(0, 0, 0, 0.08)
    love.graphics.rectangle("fill", 0, GROUND_Y - 26, WINDOW_WIDTH, 26)

    love.graphics.setColor(0.33, 0.33, 0.36)
    love.graphics.rectangle("fill", 0, GROUND_Y, WINDOW_WIDTH, GROUND_HEIGHT)
    love.graphics.setColor(0.46, 0.46, 0.50)
    love.graphics.rectangle("fill", 0, GROUND_Y, WINDOW_WIDTH, 10)

    -- Puis on dessine le sol qui defile en petits blocs.
    for i = -1, math.ceil(WINDOW_WIDTH / 48) + 1 do
        local x = i * 48 - groundOffset
        love.graphics.setColor(0.48, 0.48, 0.52)
        love.graphics.rectangle("fill", x, GROUND_Y + 12, 42, 24, 4, 4)
        love.graphics.setColor(0.24, 0.24, 0.26)
        love.graphics.rectangle("fill", x, GROUND_Y + 42, 42, 32, 4, 4)
    end
end

-- Dessine le joueur avec un angle base sur sa vitesse verticale.
function drawBird()
    -- L'oiseau se penche vers le haut ou le bas selon sa vitesse.
    local angle = math.max(-0.35, math.min(0.65, bird.speedY / 420))
    local cx = bird.x + bird.width / 2
    local cy = bird.y + bird.height / 2
    local activeBirdIndex = getActiveBirdIndex()
    local image, quad, frameWidth, frameHeight = getBirdSpriteVisual(activeBirdIndex)

    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.rotate(angle)

    if image ~= nil then
        local scale = math.min(bird.width / frameWidth, bird.height / frameHeight) * getBirdScaleMultiplier(activeBirdIndex, false)
        drawSprite(image, quad, 0, 0, 0, scale, scale, frameWidth / 2, frameHeight / 2)
        love.graphics.pop()
        return
    end

    love.graphics.setColor(1, 0.82, 0.18)
    love.graphics.ellipse("fill", 0, 0, 20, 15)
    love.graphics.pop()
end

-- Dessine tous les tuyaux actifs.
function drawPipes()
    local activePipeIndex = getActivePipeIndex()
    local image, data = getPipeSpriteVisual(activePipeIndex)
    local overscan = 6

    for i = 1, #pipes do
        local pipe = pipes[i]
        local bottomY = pipe.topHeight + pipeGap
        local bottomHeight = GROUND_Y - bottomY

        if image ~= nil and data ~= nil then
            drawPipeWithOutline(image, data, pipe.x, -overscan, pipeWidth, pipe.topHeight + overscan, true)
            drawPipeWithOutline(image, data, pipe.x, bottomY, pipeWidth, bottomHeight + overscan, false)
        end
    end
end

-- Dessine les pieces ramassables.
function drawCoins()
    for i = 1, #coinsOnMap do
        local item = coinsOnMap[i]
        local cx = item.x + item.size / 2
        local cy = item.y + item.size / 2
        local image, quad, frameWidth, frameHeight = getPickupSpriteVisual(item.type)

        if image ~= nil then
            local scale = math.min(40 / frameWidth, 40 / frameHeight)
            love.graphics.setColor(1, 1, 1)
            if quad ~= nil then
                love.graphics.draw(image, quad, cx, cy, 0, scale, scale, frameWidth / 2, frameHeight / 2)
            else
                love.graphics.draw(image, cx, cy, 0, scale, scale, frameWidth / 2, frameHeight / 2)
            end
        end
    end
end

-- Dessine les vies restantes.
function drawLivesAt(startX, startY)
    for i = 1, maxLives do
        local x = startX + (i - 1) * 36

        if heartsSprite ~= nil and heartFullQuad ~= nil and heartEmptyQuad ~= nil then
            local quad = i <= lives and heartFullQuad or heartEmptyQuad
            local scale = math.min(30 / heartFrameWidth, 28 / heartFrameHeight)
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(heartsSprite, quad, x, startY, 0, scale, scale)
        else
            if i <= lives then
                love.graphics.setColor(1, 0.3, 0.3)
            else
                love.graphics.setColor(0.4, 0.2, 0.2)
            end
            love.graphics.rectangle("fill", x, startY, 20, 18)
        end
    end
end

function drawCoinCounter()
    local panelX = 18
    local panelY = 16
    local panelWidth = 152
    local panelHeight = 52
    local iconX = panelX + 18
    local iconY = panelY + 11
    local image, quad, frameWidth, frameHeight = getCoinSpriteVisual("gold")

    drawSoftPanel(panelX, panelY, panelWidth, panelHeight, { 1, 0.86, 0.25, 0.28 })

    if image ~= nil then
        local scale = math.min(28 / frameWidth, 28 / frameHeight)
        love.graphics.setColor(1, 1, 1)
        if quad ~= nil then
            love.graphics.draw(image, quad, iconX + 14, iconY + 14, 0, scale, scale, frameWidth / 2, frameHeight / 2)
        else
            love.graphics.draw(image, iconX + 14, iconY + 14, 0, scale, scale, frameWidth / 2, frameHeight / 2)
        end
    else
        love.graphics.setColor(1, 0.88, 0.20)
        love.graphics.circle("fill", iconX + 14, iconY + 14, 14)
    end

    love.graphics.setFont(fontUI)
    love.graphics.setColor(0, 0, 0, 0.22)
    love.graphics.print("x " .. tostring(coins + coinsRun), panelX + 58, panelY + 15)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("x " .. tostring(coins + coinsRun), panelX + 56, panelY + 13)
end

function drawPauseHint()
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("P : pause", 24, 76)
end

-- Dessine les informations de HUD pendant la partie.
function drawGameUI()
    drawSoftPanel(WINDOW_WIDTH - 290, 16, 262, 130, { 1, 1, 1, 0.18 })
    drawCoinCounter()
    drawPauseHint()

    love.graphics.setFont(fontScore)
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.printf(tostring(score), 2, 16, WINDOW_WIDTH, "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(tostring(score), 0, 14, WINDOW_WIDTH, "center")

    love.graphics.setFont(fontUI)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Meilleur : " .. getBestScore(difficultyMode), WINDOW_WIDTH - 270, 34)
    love.graphics.print("Mode : " .. getDifficultyLabel(difficultyMode), WINDOW_WIDTH - 270, 76)

    love.graphics.setFont(fontUI)
    drawLivesAt(18, GROUND_Y - 66)
end

-- Ecran principal d'une partie en cours.
function drawPlaying()
    drawBackground()

    drawPipes()
    drawCoins()
    drawBird()
    drawGameUI()
end

-- Overlay de pause.
function drawPaused()
    drawPlaying()

    local boxWidth = 420
    local boxHeight = 130
    local boxX = (WINDOW_WIDTH - boxWidth) / 2
    local boxY = (WINDOW_HEIGHT - boxHeight) / 2

    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 12, 12)

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Pause", 0, boxY + 20, WINDOW_WIDTH, "center")

    love.graphics.setFont(fontSmall)
    love.graphics.printf("P pour reprendre - Échap pour le menu", 0, boxY + 76, WINDOW_WIDTH, "center")
end

-- -------------------------------------------------------------------
-- MENUS
-- -------------------------------------------------------------------

function drawMenu()
    drawBackground()

    local panelWidth = 960
    local panelHeight = 640
    local panelX = (WINDOW_WIDTH - panelWidth) / 2
    local panelY = 34
    local footerY = panelY + panelHeight - 58
    local buttonY = panelY + 170
    local selectedButtonKey = "play"
    local buttonLayout = {
        { x = 0.16, y = 0.07, w = 0.52, h = 0.16 },
        { x = 0.16, y = 0.29, w = 0.52, h = 0.16 },
        { x = 0.16, y = 0.52, w = 0.52, h = 0.16 },
        { x = 0.16, y = 0.74, w = 0.52, h = 0.16 }
    }

    menuButtonBounds = {}

    if menuIndex == 2 then
        selectedButtonKey = "shop"
    elseif menuIndex == 3 then
        selectedButtonKey = "reset"
    elseif menuIndex == 4 then
        selectedButtonKey = "out"
    end

    if menuBackgroundSprite ~= nil then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            menuBackgroundSprite,
            panelX,
            panelY,
            0,
            panelWidth / menuBackgroundSprite:getWidth(),
            panelHeight / menuBackgroundSprite:getHeight()
        )
    else
        love.graphics.setColor(0, 0, 0, 0.24)
        love.graphics.rectangle("fill", panelX + 10, panelY + 10, panelWidth, panelHeight, 18, 18)
        love.graphics.setColor(0.86, 0.78, 0.62, 0.98)
        love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 18, 18)
        love.graphics.setColor(0.64, 0.56, 0.43, 0.95)
        love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 18, 18)
    end

    local selectedButton = menuButtonSprites[selectedButtonKey]
    if selectedButton ~= nil then
        local buttonWidth = math.min(panelWidth - 360, selectedButton:getWidth() * 0.62)
        local buttonScale = buttonWidth / selectedButton:getWidth()
        local buttonHeight = selectedButton:getHeight() * buttonScale
        local buttonX = panelX + (panelWidth - buttonWidth) / 2

        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(selectedButton, buttonX, buttonY, 0, buttonScale, buttonScale)

        for i = 1, #buttonLayout do
            local item = buttonLayout[i]
            menuButtonBounds[i] = {
                x = buttonX + item.x * buttonWidth,
                y = buttonY + item.y * buttonHeight,
                w = item.w * buttonWidth,
                h = item.h * buttonHeight
            }
        end
    else
        love.graphics.setFont(fontSmall)
        love.graphics.setColor(1, 0.82, 0.82)
        love.graphics.printf("Bouton du menu introuvable", 0, buttonY + 52, WINDOW_WIDTH, "center")
        if menuButtonLoadErrors ~= nil and menuButtonLoadErrors[selectedButtonKey] ~= nil then
            love.graphics.setColor(1, 0.88, 0.88)
            love.graphics.printf(menuButtonLoadErrors[selectedButtonKey], panelX + 24, buttonY + 84, panelWidth - 48, "center")
        end
    end

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.28, 0.23, 0.18, 0.92)
    love.graphics.printf("Haut / Bas pour choisir - Entrée pour valider", 0, footerY, WINDOW_WIDTH, "center")
end

function drawDifficultyMenu()
    drawBackground()

    local panelWidth = 760
    local panelHeight = 360
    local panelX = (WINDOW_WIDTH - panelWidth) / 2
    local panelY = WINDOW_HEIGHT * 0.18
    local titleY = panelY + 28
    local firstItemY = panelY + 102
    local helpY = panelY + 250

    if menuBackgroundSprite ~= nil then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            menuBackgroundSprite,
            panelX,
            panelY,
            0,
            panelWidth / menuBackgroundSprite:getWidth(),
            panelHeight / menuBackgroundSprite:getHeight()
        )
    else
        love.graphics.setColor(0, 0, 0, 0.24)
        love.graphics.rectangle("fill", panelX + 10, panelY + 10, panelWidth, panelHeight, 18, 18)
        love.graphics.setColor(0.86, 0.78, 0.62, 0.98)
        love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 18, 18)
        love.graphics.setColor(0.64, 0.56, 0.43, 0.95)
        love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 18, 18)
    end

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.printf("Choix de la difficulté", 2, titleY + 2, WINDOW_WIDTH, "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Choix de la difficulté", 0, titleY, WINDOW_WIDTH, "center")

    for i = 1, #difficultyOptions do
        local item = difficultyOptions[i]
        local cardX = panelX + 34
        local cardY = firstItemY + (i - 1) * 66
        local cardWidth = panelWidth - 68
        local isSelected = i == difficultyIndex

        if isSelected then
            drawSoftPanel(cardX, cardY, cardWidth, 56, { 1, 0.88, 0.24, 0.90 })
        else
            drawSoftPanel(cardX, cardY, cardWidth, 56, { 1, 1, 1, 0.10 })
        end

        love.graphics.setFont(fontUI)
        if isSelected then
            love.graphics.setColor(1, 0.9, 0.2)
        else
            love.graphics.setColor(1, 1, 1)
        end

        love.graphics.print(item.label, cardX + 18, cardY + 8)

        love.graphics.setFont(fontSmall)
        love.graphics.setColor(0.84, 0.90, 0.98)
        love.graphics.print("Meilleur score : " .. getBestScore(item.key), cardX + 18, cardY + 31)
    end

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Haut / Bas pour choisir - Entrée pour valider - Échap pour retour", 0, helpY, WINDOW_WIDTH, "center")
end

function drawResetConfirm()
    drawBackground()

    local boxWidth = 620
    local boxHeight = 240
    local boxX = (WINDOW_WIDTH - boxWidth) / 2
    local boxY = (WINDOW_HEIGHT - boxHeight) / 2

    drawSoftPanel(boxX, boxY, boxWidth, boxHeight, { 1, 0.30, 0.30, 0.85 })

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Reset du jeu", 0, boxY + 28, WINDOW_WIDTH, "center")

    love.graphics.setFont(fontUI)
    love.graphics.setColor(1, 0.92, 0.25)
    love.graphics.printf("Cette action remet toute la progression à zéro.", 0, boxY + 94, WINDOW_WIDTH, "center")

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.90, 0.94, 1)
    love.graphics.printf("Scores, pièces, skins débloqués et sélections seront effacés.", 0, boxY + 132, WINDOW_WIDTH, "center")
    love.graphics.printf("Entrée = confirmer   Échap = annuler", 0, boxY + 178, WINDOW_WIDTH, "center")
end

-- -------------------------------------------------------------------
-- BOUTIQUE
-- -------------------------------------------------------------------

function getShopAccent(category)
    if category == "bird" then
        return 1, 0.66, 0.24
    elseif category == "background" then
        return 0.34, 0.82, 0.74
    end

    return 0.44, 0.76, 1
end

-- Retourne le texte principal et secondaire d'une carte boutique.
function getShopStatus(item, unlocked, selected)
    -- Le rainbow n'est jamais achete manuellement.
    if item.key == "rainbow" then
        if getGlobalBestScore() >= 100 then
            return "Spécial", "S'active automatiquement à 100 points"
        end

        return "Vitrine fermée", "Atteins 100 points pour le voir en jeu"
    end

    if selected then
        return "Équipé", "Prêt à jouer"
    end

    if unlocked then
        return "Disponible", "Touche " .. tostring(item.shopIndex) .. " pour équiper"
    end

    return "À vendre", tostring(item.cost) .. " pièces"
end

function getShopShortcutLabel(item)
    if item.key == "rainbow" then
        return "SPECIAL"
    end

    return "TOUCHE " .. tostring(item.shopIndex)
end

function getShopFooterLabel(item, unlocked, selected)
    if item.key == "rainbow" then
        return "Auto 100 pts"
    elseif selected then
        return "Equipe"
    elseif unlocked then
        return "Choisir"
    end

    return tostring(item.cost) .. " pièces"
end

function getShopTopBadgeLabel(item, unlocked, selected)
    if item.key == "rainbow" then
        if unlocked then
            return nil
        end

        return "100 pts"
    end

    if unlocked or selected then
        return nil
    end

    return tostring(item.cost) .. " pieces"
end

function getShopStateSpriteKey(item, unlocked, selected)
    if item.key == "rainbow" and not unlocked and getGlobalBestScore() < 100 then
        return "lock"
    elseif selected then
        return "use"
    elseif unlocked then
        return "unlock"
    end

    return "lock"
end

-- Dessine une carte produit.
function drawShopCard(category, itemIndex, item, unlocked, selected, x, y, w, h)
    local accentR, accentG, accentB = getShopAccent(category)
    local stateSpriteKey = getShopStateSpriteKey(item, unlocked, selected)
    local stateSprite = shopSkinStateSprites[stateSpriteKey]
    local topBadgeLabel = getShopTopBadgeLabel(item, unlocked, selected)
    local previewX = x + w * 0.17
    local previewY = y + h * 0.20
    local previewW = w * 0.66
    local previewH = h * 0.42

    love.graphics.setColor(0, 0, 0, 0.16)
    love.graphics.rectangle("fill", x + 8, y + 10, w, h, 10, 10)

    if stateSprite ~= nil then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(stateSprite, x, y, 0, w / stateSprite:getWidth(), h / stateSprite:getHeight())
    else
        if selected then
            love.graphics.setColor(accentR, accentG, accentB, 0.12)
            love.graphics.rectangle("fill", x - 4, y - 4, w + 8, h + 8, 12, 12)
        end

        love.graphics.setColor(0.93, 0.95, 1.0, 0.98)
        love.graphics.rectangle("fill", x, y, w, h, 10, 10)
        love.graphics.setColor(0.70, 0.76, 0.90, 1)
        love.graphics.rectangle("line", x, y, w, h, 10, 10)
    end

    if stateSprite ~= nil and topBadgeLabel ~= nil then
        love.graphics.setFont(fontSmall)
        love.graphics.setColor(0.12, 0.12, 0.12, 0.98)
        love.graphics.printf(topBadgeLabel, x + w * 0.24, y + h * 0.074, w * 0.52, "center")
    end

    -- La miniature depend de ce qu'on vend.
    if category == "bird" then
        drawBirdPreview(itemIndex, x + (w - 50) / 2, y + h * 0.40, 1.05)
    elseif category == "background" then
        love.graphics.setScissor(previewX, previewY, previewW, previewH)
        drawBackgroundPreview(itemIndex, previewX, previewY, previewW, previewH)
        love.graphics.setScissor()
    else
        drawPipePreview(itemIndex, x + (w - 74) / 2, y + h * 0.33, 1.08)
    end
end

-- Dessine une rangée complète de cartes.
function drawShopShelf(category, list, unlockedList, selected, visibleIndices, x, y, cardW, cardH, spacing)
    for visibleIndex, itemIndex in ipairs(visibleIndices) do
        local item = list[itemIndex]
        item.shopIndex = visibleIndex

        local cardX = x + (visibleIndex - 1) * (cardW + spacing)
        drawShopCard(category, itemIndex, item, unlockedList[itemIndex] == true, selected == itemIndex, cardX, y, cardW, cardH)
    end
end

function drawShopArrowButton(x, y, w, h, direction, enabled, accentR, accentG, accentB)
    return
end

function drawShopBalanceBadge(panelX, panelY, panelWidth, panelHeight)
    local labelX = panelX + panelWidth * 0.08
    local labelY = panelY + panelHeight * 0.87
    local labelW = panelWidth * 0.36
    local labelH = panelHeight * 0.10

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.12, 0.12, 0.12, 0.98)
    love.graphics.printf(tostring(coins), labelX + labelW * 0.50, labelY + labelH * 0.06, labelW * 0.22, "center")
end

-- Regroupe les données du rayon actif pour simplifier drawShop.
function getActiveShopData()
    if shopSection == "background" then
        return "Décors", backgroundSkins, unlockedBackgrounds, selectedBackground
    elseif shopSection == "pipe" then
        return "Tuyaux", pipeSkins, unlockedPipes, selectedPipe
    end

    return "Oiseaux", birdSkins, unlockedBirds, selectedBird
end

function countVisibleShopItems(list)
    local count = 0

    for i = 1, #list do
        if not list[i].hidden then
            count = count + 1
        end
    end

    return count
end

function drawShop()
    drawBackground()

    local _, activeList, activeUnlocked, activeSelected = getActiveShopData()
    local accentR, accentG, accentB = getShopAccent(shopSection)
    local visibleIndices, currentPage, pageCount = getShopPageIndices(shopSection, activeList)
    local activeShopBackground = getShopBackgroundVisual(shopSection, currentPage)
    local basePanelWidth = 1092
    local basePanelHeight = 773
    if activeShopBackground ~= nil then
        basePanelWidth = activeShopBackground:getWidth()
        basePanelHeight = activeShopBackground:getHeight()
    end

    local scale = math.min((WINDOW_WIDTH - 120) / basePanelWidth, (WINDOW_HEIGHT - 24) / basePanelHeight)
    local panelWidth = math.floor(basePanelWidth * scale)
    local panelHeight = math.floor(basePanelHeight * scale)
    local panelX = (WINDOW_WIDTH - panelWidth) / 2
    local panelY = 8
    local cardW = math.floor(panelWidth * 0.255)
    local cardH = cardW
    local cardGap = math.floor(panelWidth * 0.05)

    if activeShopBackground ~= nil then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            activeShopBackground,
            panelX,
            panelY,
            0,
            panelWidth / activeShopBackground:getWidth(),
            panelHeight / activeShopBackground:getHeight()
        )
    else
        love.graphics.setColor(0, 0, 0, 0.24)
        love.graphics.rectangle("fill", panelX + 10, panelY + 10, panelWidth, panelHeight, 18, 18)
        love.graphics.setColor(0.86, 0.78, 0.62, 0.98)
        love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 18, 18)
        love.graphics.setColor(0.64, 0.56, 0.43, 0.95)
        love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 18, 18)
    end

    local visibleItemCount = #visibleIndices
    local rowWidth = (visibleItemCount * cardW) + math.max(0, visibleItemCount - 1) * cardGap
    local rowX = panelX + (panelWidth - rowWidth) / 2
    local arrowW = math.floor(panelWidth * 0.145)
    local arrowH = math.floor(panelHeight * 0.235)
    local arrowY = panelY + math.floor(panelHeight * 0.525)
    local leftEnabled = currentPage > 1
    local rightEnabled = currentPage < pageCount

    shopArrowBounds.left = nil
    shopArrowBounds.right = nil

    if pageCount > 1 then
        shopArrowBounds.left = { x = panelX - math.floor(arrowW * 0.10), y = arrowY, w = arrowW, h = arrowH }
        shopArrowBounds.right = { x = panelX + panelWidth - arrowW + math.floor(arrowW * 0.10), y = arrowY, w = arrowW, h = arrowH }
    end

    drawShopBalanceBadge(panelX, panelY, panelWidth, panelHeight)

    if pageCount > 1 then
        drawShopArrowButton(shopArrowBounds.left.x, shopArrowBounds.left.y, arrowW, arrowH, "left", leftEnabled, accentR, accentG, accentB)
        drawShopArrowButton(shopArrowBounds.right.x, shopArrowBounds.right.y, arrowW, arrowH, "right", rightEnabled, accentR, accentG, accentB)
    end

    drawShopShelf(shopSection, activeList, activeUnlocked, activeSelected, visibleIndices, rowX, panelY + math.floor(panelHeight * 0.33), cardW, cardH, cardGap)
end

-- -------------------------------------------------------------------
-- GAME OVER
-- -------------------------------------------------------------------

-- Écran de fin de partie plus lisible avec récapitulatif.
function drawGameOver()
    -- On garde la partie visible dessous, puis on pose un panneau sombre dessus.
    drawBackground()
    drawPipes()
    drawCoins()
    drawBird()

    love.graphics.setColor(0, 0, 0, 0.52)
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

    local boxWidth = 760
    local boxHeight = 360
    local boxX = (WINDOW_WIDTH - boxWidth) / 2
    local boxY = (WINDOW_HEIGHT - boxHeight) / 2

    drawSoftPanel(boxX, boxY, boxWidth, boxHeight, { 1, 0.35, 0.30, 0.90 })

    love.graphics.setColor(1, 0.34, 0.30, 0.16)
    love.graphics.rectangle("fill", boxX + 18, boxY + 18, boxWidth - 36, 72, 18, 18)

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Game Over", boxX, boxY + 28, boxWidth, "center")

    love.graphics.setFont(fontUI)
    love.graphics.setColor(1, 0.92, 0.25)
    love.graphics.printf("La course est terminée", boxX, boxY + 90, boxWidth, "center")

    local cards = {
        { title = "Score final", value = tostring(score), x = boxX + 34 },
        { title = "Meilleur score", value = tostring(getBestScore(difficultyMode)), x = boxX + 218 },
        { title = "Pièces gagnées", value = tostring(coinsRun), x = boxX + 402 },
        { title = "Mode", value = getDifficultyLabel(difficultyMode), x = boxX + 586 }
    }

    for i = 1, #cards do
        local item = cards[i]
        drawSoftPanel(item.x, boxY + 138, 140, 104, { 1, 1, 1, 0.12 })
        love.graphics.setFont(fontSmall)
        love.graphics.setColor(0.85, 0.90, 1)
        love.graphics.printf(item.title, item.x, boxY + 154, 140, "center")
        love.graphics.setFont(fontUI)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(item.value, item.x, boxY + 188, 140, "center")
    end

    local rainbowText = "Le tuyau rainbow s'active automatiquement à 100 points."
    if score >= 100 then
        rainbowText = "Le tuyau rainbow s'est activé pendant cette partie."
    elseif getGlobalBestScore() >= 100 then
        rainbowText = "Tu as déjà atteint 100 points au moins une fois."
    end

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.94, 0.88, 1)
    love.graphics.printf(rainbowText, boxX + 34, boxY + 266, boxWidth - 68, "center")

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Entrée = recommencer   Échap = menu", boxX, boxY + 310, boxWidth, "center")
end

function drawGameOverPanel()
    drawBackground()
    drawPipes()
    drawCoins()
    drawBird()

    love.graphics.setColor(0, 0, 0, 0.62)
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

    local boxWidth = 840
    local boxHeight = 430
    local boxX = (WINDOW_WIDTH - boxWidth) / 2
    local boxY = (WINDOW_HEIGHT - boxHeight) / 2

    drawSoftPanel(boxX, boxY, boxWidth, boxHeight, { 1, 0.35, 0.30, 0.90 })

    love.graphics.setColor(1, 0.34, 0.30, 0.18)
    love.graphics.rectangle("fill", boxX + 22, boxY + 22, boxWidth - 44, 84, 22, 22)
    love.graphics.setColor(1, 0.90, 0.28, 0.10)
    love.graphics.circle("fill", boxX + 88, boxY + 74, 34)
    love.graphics.circle("fill", boxX + boxWidth - 94, boxY + 72, 28)

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Game Over", boxX, boxY + 34, boxWidth, "center")

    love.graphics.setFont(fontUI)
    love.graphics.setColor(1, 0.92, 0.25)
    love.graphics.printf("La course est terminée, sal noob", boxX, boxY + 92, boxWidth, "center")

    local cards = {
        { title = "Score final", value = tostring(score), x = boxX + 38, accent = { 1.00, 0.84, 0.24 } },
        { title = "Meilleur score", value = tostring(getBestScore(difficultyMode)), x = boxX + 238, accent = { 0.48, 0.84, 1.00 } },
        { title = "Pièces gagnées", value = tostring(coinsRun), x = boxX + 438, accent = { 0.98, 0.72, 0.30 } },
        { title = "Mode", value = getDifficultyLabel(difficultyMode), x = boxX + 638, accent = { 0.62, 0.90, 0.72 } }
    }

    for i = 1, #cards do
        local item = cards[i]
        drawSoftPanel(item.x, boxY + 144, 164, 122, { item.accent[1], item.accent[2], item.accent[3], 0.34 })
        love.graphics.setColor(item.accent[1], item.accent[2], item.accent[3], 0.12)
        love.graphics.rectangle("fill", item.x + 10, boxY + 154, 144, 34, 10, 10)
        love.graphics.setFont(fontSmall)
        love.graphics.setColor(0.85, 0.90, 1)
        love.graphics.printf(item.title, item.x, boxY + 164, 164, "center")
        love.graphics.setFont(fontUI)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(item.value, item.x, boxY + 212, 164, "center")
    end

    local rainbowText = "Le tuyau rainbow s'active automatiquement à 100 points."
    if score >= 100 then
        rainbowText = "Le tuyau rainbow s'est active pendant cette partie."
    elseif getGlobalBestScore() >= 100 then
        rainbowText = "Tu as déjà atteint 100 points au moins une fois."
    end

    drawSoftPanel(boxX + 38, boxY + 288, boxWidth - 76, 58, { 1, 1, 1, 0.12 })
    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.94, 0.88, 1)
    love.graphics.printf(rainbowText, boxX + 58, boxY + 308, boxWidth - 116, "center")

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.86, 0.90, 0.96)
    love.graphics.printf("Les coins ramassés sont les seules pièces gagnées pendant la partie.", boxX + 58, boxY + 360, boxWidth - 116, "center")

    drawSoftPanel(boxX + 126, boxY + 386, 246, 26, { 1, 0.88, 0.24, 0.28 })
    drawSoftPanel(boxX + boxWidth - 372, boxY + 386, 246, 26, { 1, 1, 1, 0.16 })
    love.graphics.setColor(1, 0.92, 0.25)
    love.graphics.printf("Entrée = recommencer", boxX + 126, boxY + 391, 246, "center")
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Échap = menu", boxX + boxWidth - 372, boxY + 391, 246, "center")
end

-- -------------------------------------------------------------------
-- ROUTEUR D'ECRAN
-- -------------------------------------------------------------------

-- Choisit quoi dessiner selon l'état global du jeu.
function drawCurrentScreen()
    if state == "menu" then
        drawMenu()
    elseif state == "reset_confirm" then
        drawResetConfirm()
    elseif state == "difficulty" then
        drawDifficultyMenu()
    elseif state == "shop" then
        drawShop()
    elseif state == "playing" then
        drawPlaying()
    elseif state == "paused" then
        drawPaused()
    elseif state == "gameover" then
        drawGameOverPanel()
    end
end
