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

function drawBirdPreview(index, x, y, w, h, scaleMultiplier)
    local image, quad, frameWidth, frameHeight = getBirdSpriteVisual(index)
    local previewScaleMultiplier = scaleMultiplier or 1

    if image == nil then
        return
    end

    local scale = math.min(w / frameWidth, h / frameHeight) * getBirdScaleMultiplier(index, true) * previewScaleMultiplier
    drawSprite(image, quad, x + w / 2, y + h / 2, 0, scale, scale, frameWidth / 2, frameHeight / 2)
end

function drawBackgroundPreview(index, x, y, w, h)
    local image = backgroundSprites[index]

    if image == nil then
        return
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(image, x, y, 0, w / image:getWidth(), h / image:getHeight())
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

-- Dessine les pièces ramassables.
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

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        menuBackgroundSprite,
        panelX,
        panelY,
        0,
        panelWidth / menuBackgroundSprite:getWidth(),
        panelHeight / menuBackgroundSprite:getHeight()
    )

    local selectedButton = menuButtonSprites[selectedButtonKey]
    if selectedButton == nil then
        return
    end

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

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.28, 0.23, 0.18, 0.92)
    love.graphics.printf("Haut / Bas pour choisir - Entrée pour valider", 0, footerY, WINDOW_WIDTH, "center")
end

function drawDifficultyMenu()
    drawBackground()

    local selectedMode = difficultyOptions[difficultyIndex] and difficultyOptions[difficultyIndex].key or "normal"
    local difficultyBackground = getDifficultyBackgroundVisual(selectedMode)
    local panelWidth = 760
    local panelHeight = 360
    if difficultyBackground ~= nil then
        panelWidth = difficultyBackground:getWidth()
        panelHeight = difficultyBackground:getHeight()
    end
    local panelX = (WINDOW_WIDTH - panelWidth) / 2
    local panelY = WINDOW_HEIGHT * 0.18
    if difficultyBackground ~= nil then
        panelY = (WINDOW_HEIGHT - panelHeight) / 2
    end
    local titleY = panelY + 28
    local firstItemY = panelY + 102
    local helpY = panelY + 250

    if difficultyBackground ~= nil then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            difficultyBackground,
            panelX,
            panelY,
            0,
            panelWidth / difficultyBackground:getWidth(),
            panelHeight / difficultyBackground:getHeight()
        )
        return
    elseif menuBackgroundSprite ~= nil then
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

    local resetBackground = getResetBackgroundVisual()
    local boxWidth = 620
    local boxHeight = 240
    if resetBackground ~= nil then
        boxWidth = resetBackground:getWidth()
        boxHeight = resetBackground:getHeight()
    end
    local boxX = (WINDOW_WIDTH - boxWidth) / 2
    local boxY = (WINDOW_HEIGHT - boxHeight) / 2

    if resetBackground ~= nil then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            resetBackground,
            boxX,
            boxY,
            0,
            boxWidth / resetBackground:getWidth(),
            boxHeight / resetBackground:getHeight()
        )
        return
    end

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

-- Retourne le texte principal et secondaire d'une carte boutique.

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

    return tostring(item.cost) .. " pièces"
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
    local stateSpriteKey = getShopStateSpriteKey(item, unlocked, selected)
    local stateSprite = shopSkinStateSprites[stateSpriteKey]
    local topBadgeLabel = getShopTopBadgeLabel(item, unlocked, selected)
    local previewX = x + w * 0.17
    local previewY = y + h * 0.20
    local previewW = w * 0.66
    local previewH = h * 0.42

    love.graphics.setColor(0, 0, 0, 0.16)
    love.graphics.rectangle("fill", x + 8, y + 10, w, h, 10, 10)

    if stateSprite == nil then
        return
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(stateSprite, x, y, 0, w / stateSprite:getWidth(), h / stateSprite:getHeight())

    if topBadgeLabel ~= nil then
        love.graphics.setFont(fontSmall)
        love.graphics.setColor(0.12, 0.12, 0.12, 0.98)
        love.graphics.printf(topBadgeLabel, x + w * 0.255, y + h * 0.095, w * 0.52, "center")
    end

    -- La miniature dépend de ce qu'on vend.
    if category == "bird" then
        drawBirdPreview(itemIndex, x + w * 0.17, y + h * 0.32, w * 0.66, h * 0.36, 1.10)
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

function drawShopBalanceBadge(panelX, panelY, panelWidth, panelHeight)
    local labelX = panelX + panelWidth * 0.08
    local labelY = panelY + panelHeight * 0.87
    local labelW = panelWidth * 0.36
    local labelH = panelHeight * 0.10

    love.graphics.setFont(fontSmall)
    love.graphics.setColor(0.12, 0.12, 0.12, 0.98)
    love.graphics.printf(tostring(coins), labelX + labelW * 0.50, labelY - labelH * 0.01, labelW * 0.22, "center")
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


function drawShop()
    drawBackground()

    local _, activeList, activeUnlocked, activeSelected = getActiveShopData()
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

    if activeShopBackground == nil then
        return
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        activeShopBackground,
        panelX,
        panelY,
        0,
        panelWidth / activeShopBackground:getWidth(),
        panelHeight / activeShopBackground:getHeight()
    )

    local visibleItemCount = #visibleIndices
    local rowWidth = (visibleItemCount * cardW) + math.max(0, visibleItemCount - 1) * cardGap
    local rowX = panelX + (panelWidth - rowWidth) / 2
    local arrowW = math.floor(panelWidth * 0.145)
    local arrowH = math.floor(panelHeight * 0.235)
    local arrowY = panelY + math.floor(panelHeight * 0.525)
    shopArrowBounds.left = nil
    shopArrowBounds.right = nil

    if pageCount > 1 then
        shopArrowBounds.left = { x = panelX - math.floor(arrowW * 0.10), y = arrowY, w = arrowW, h = arrowH }
        shopArrowBounds.right = { x = panelX + panelWidth - arrowW + math.floor(arrowW * 0.10), y = arrowY, w = arrowW, h = arrowH }
    end

    drawShopBalanceBadge(panelX, panelY, panelWidth, panelHeight)

    drawShopShelf(shopSection, activeList, activeUnlocked, activeSelected, visibleIndices, rowX, panelY + math.floor(panelHeight * 0.33), cardW, cardH, cardGap)
end

-- -------------------------------------------------------------------
-- GAME OVER
-- -------------------------------------------------------------------

-- Écran de fin de partie plus lisible avec récapitulatif.

function drawGameOverPanel()
    drawBackground()
    drawPipes()
    drawCoins()
    drawBird()

    local gameOverBackground = getGameOverBackgroundVisual(difficultyMode)
    local boxWidth = 840
    local boxHeight = 430
    if gameOverBackground ~= nil then
        boxWidth = gameOverBackground:getWidth()
        boxHeight = gameOverBackground:getHeight()
    end
    local boxX = (WINDOW_WIDTH - boxWidth) / 2
    local boxY = (WINDOW_HEIGHT - boxHeight) / 2

    love.graphics.setColor(0, 0, 0, 0.62)
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

    if gameOverBackground ~= nil then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            gameOverBackground,
            boxX,
            boxY,
            0,
            boxWidth / gameOverBackground:getWidth(),
            boxHeight / gameOverBackground:getHeight()
        )

        love.graphics.setFont(fontUI)
        love.graphics.setColor(0.08, 0.08, 0.08, 1)
        love.graphics.printf(tostring(coinsRun), boxX + boxWidth * 0.08, boxY + boxHeight * 0.53, boxWidth * 0.40, "center")
        love.graphics.printf(tostring(score), boxX + boxWidth * 0.35, boxY + boxHeight * 0.53, boxWidth * 0.30, "center")
        return
    end

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
