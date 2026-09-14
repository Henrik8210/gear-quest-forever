local _, GQ = ...

GQ.Spec = GQ.Spec or {}

GQ.Spec.TALENT_LEVEL = 10

-- Talent tab index (1–3) -> spec id per class (TBC Classic order).
local SPEC_BY_TAB = {
    WARRIOR = { "arms", "fury", "protection" },
    PALADIN = { "holy", "protection", "retribution" },
    HUNTER = { "beast_mastery", "marksmanship", "survival" },
    ROGUE = { "assassination", "combat", "subtlety" },
    PRIEST = { "discipline", "holy", "shadow" },
    SHAMAN = { "elemental", "enhancement", "restoration" },
    MAGE = { "arcane", "fire", "frost" },
    WARLOCK = { "affliction", "demonology", "destruction" },
    DRUID = { "balance", "feral", "restoration" },
}

-- classFile -> spec options (id, label, icon, default for leveling BiS, comingLater)
GQ.Spec.CLASS_SPECS = {
    WARRIOR = {
        { id = "arms", label = "Arms", icon = "Interface\\Icons\\Ability_Warrior_SavageBlow", default = true },
        { id = "fury", label = "Fury", icon = "Interface\\Icons\\Ability_Warrior_InnerRage" },
        { id = "protection", label = "Protection", icon = "Interface\\Icons\\Ability_Warrior_DefensiveStance" },
    },
    PALADIN = {
        { id = "retribution", label = "Retribution", icon = "Interface\\Icons\\Spell_Holy_AuraOfLight", default = true },
        { id = "holy", label = "Holy", icon = "Interface\\Icons\\Spell_Holy_HolyBolt" },
        { id = "protection", label = "Protection", icon = "Interface\\Icons\\Spell_Holy_DevotionAura" },
    },
    HUNTER = {
        { id = "beast_mastery", label = "Beast Mastery", icon = "Interface\\Icons\\Ability_Hunter_BeastTaming", default = true },
        { id = "marksmanship", label = "Marksmanship", icon = "Interface\\Icons\\Ability_Hunter_AimedShot" },
        { id = "survival", label = "Survival", icon = "Interface\\Icons\\Ability_Hunter_SwiftStrike" },
    },
    ROGUE = {
        { id = "combat", label = "Combat", icon = "Interface\\Icons\\Ability_BackStab", default = true },
        { id = "assassination", label = "Assassination", icon = "Interface\\Icons\\Ability_Rogue_Eviscerate" },
        { id = "subtlety", label = "Subtlety", icon = "Interface\\Icons\\Ability_Stealth" },
    },
    PRIEST = {
        { id = "shadow", label = "Shadow", icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain", default = true },
        { id = "discipline", label = "Discipline", icon = "Interface\\Icons\\Spell_Holy_PowerWordShield" },
        { id = "holy", label = "Holy", icon = "Interface\\Icons\\Spell_Holy_Heal" },
    },
    SHAMAN = {
        { id = "elemental", label = "Elemental", icon = "Interface\\Icons\\Spell_Nature_Lightning", default = true },
        { id = "enhancement", label = "Enhancement", icon = "Interface\\Icons\\Spell_Nature_LightningShield" },
        { id = "restoration", label = "Restoration", icon = "Interface\\Icons\\Spell_Nature_MagicImmunity" },
    },
    MAGE = {
        { id = "frost", label = "Frost", icon = "Interface\\Icons\\Spell_Frost_FrostBolt02", default = true },
        { id = "arcane", label = "Arcane", icon = "Interface\\Icons\\Spell_Holy_ArcaneIntellect" },
        { id = "fire", label = "Fire", icon = "Interface\\Icons\\Spell_Fire_FireBolt02" },
    },
    WARLOCK = {
        { id = "affliction", label = "Affliction", icon = "Interface\\Icons\\Spell_Shadow_DeathCoil", default = true },
        { id = "demonology", label = "Demonology", icon = "Interface\\Icons\\Spell_Shadow_SummonFelHunter" },
        { id = "destruction", label = "Destruction", icon = "Interface\\Icons\\Spell_Shadow_RainOfFire" },
    },
    DRUID = {
        { id = "feral", label = "Feral (Cat)", icon = "Interface\\Icons\\Ability_Druid_CatForm", default = true },
        { id = "bear", label = "Bear Tank", icon = "Interface\\Icons\\Ability_Druid_Maul" },
        { id = "balance", label = "Balance", icon = "Interface\\Icons\\Spell_Nature_StarFall" },
        { id = "restoration", label = "Restoration", icon = "Interface\\Icons\\Spell_Nature_HealingTouch" },
    },
}

local SPEC_ALIASES = {
    -- Paladin
    ret = "retribution",
    retribution = "retribution",
    holy = "holy",
    prot = "protection",
    protection = "protection",
    -- Warrior
    arms = "arms",
    fury = "fury",
    -- Hunter
    bm = "beast_mastery",
    beast = "beast_mastery",
    beastmastery = "beast_mastery",
    beast_mastery = "beast_mastery",
    mm = "marksmanship",
    marksmanship = "marksmanship",
    marks = "marksmanship",
    survival = "survival",
    surv = "survival",
    -- Rogue
    assassination = "assassination",
    assa = "assassination",
    combat = "combat",
    subtlety = "subtlety",
    sub = "subtlety",
    -- Priest
    discipline = "discipline",
    disc = "discipline",
    shadow = "shadow",
    -- Shaman
    elemental = "elemental",
    ele = "elemental",
    enhancement = "enhancement",
    enh = "enhancement",
    restoration = "restoration",
    resto = "restoration",
    rest = "restoration",
    -- Mage
    arcane = "arcane",
    fire = "fire",
    frost = "frost",
    -- Warlock
    affliction = "affliction",
    aff = "affliction",
    demonology = "demonology",
    demo = "demonology",
    destruction = "destruction",
    destro = "destruction",
    -- Druid
    balance = "balance",
    feral = "feral",
    bear = "bear",
    tank = "protection",
}

local function BuildSpecToTab(classFile)
    local byTab = SPEC_BY_TAB[classFile]
    if not byTab then
        return nil
    end
    local map = {}
    for tab, specId in ipairs(byTab) do
        map[specId] = tab
    end
    return map
end

function GQ.Spec:GetOptions(classFile)
    return self.CLASS_SPECS[classFile]
end

function GQ.Spec:HasSpecs(classFile)
    classFile = classFile or GQ:GetEffectiveClass()
    return self.CLASS_SPECS[classFile] ~= nil
end

function GQ.Spec:IsActive()
    return GQ:GetEffectiveLevel() >= self.TALENT_LEVEL and self:HasSpecs()
end

function GQ.Spec:GetDefaultSpec(classFile)
    local options = self:GetOptions(classFile)
    if not options then
        return nil
    end

    for _, opt in ipairs(options) do
        if opt.default then
            return opt.id
        end
    end

    return options[1] and options[1].id
end

function GQ.Spec:GetSpecOption(specId, classFile)
    classFile = classFile or GQ:GetEffectiveClass()
    for _, opt in ipairs(self:GetOptions(classFile) or {}) do
        if opt.id == specId then
            return opt
        end
    end
end

function GQ.Spec:IsSpecSelectable(specId, classFile)
    local opt = self:GetSpecOption(specId, classFile)
    return opt ~= nil and not opt.comingLater
end

function GQ.Spec:GetSpecLabel(specId, classFile)
    classFile = classFile or GQ:GetEffectiveClass()
    local options = self:GetOptions(classFile)
    if not options or not specId then
        return nil
    end

    for _, opt in ipairs(options) do
        if opt.id == specId then
            return opt.label
        end
    end
end

function GQ.Spec:GetSpecIcon(specId, classFile)
    classFile = classFile or GQ:GetEffectiveClass()
    local opt = self:GetSpecOption(specId, classFile)
    if opt and opt.icon then
        return opt.icon
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function GetSpecStore(previewMode)
    if previewMode then
        GearQuestDB.settings = GearQuestDB.settings or {}
        GearQuestDB.settings.preview = GearQuestDB.settings.preview or {}
        GearQuestDB.settings.preview.specByClass = GearQuestDB.settings.preview.specByClass or {}
        return GearQuestDB.settings.preview.specByClass
    end
    GearQuestDB.settings = GearQuestDB.settings or {}
    GearQuestDB.settings.specByClass = GearQuestDB.settings.specByClass or {}
    return GearQuestDB.settings.specByClass
end

function GQ.Spec:GetSavedSpec(classFile)
    classFile = classFile or GQ:GetEffectiveClass()
    local previewMode = GQ.IsPreviewEnabled and GQ:IsPreviewEnabled()
    return GetSpecStore(previewMode)[classFile]
end

function GQ.Spec:ResolveSpecInput(specId, classFile)
    specId = strtrim((specId or ""):lower())
    if specId == "" then
        return nil
    end

    specId = SPEC_ALIASES[specId] or specId

    local options = self:GetOptions(classFile) or {}
    for _, opt in ipairs(options) do
        if opt.id == specId or opt.label:lower() == specId then
            return opt.id
        end
    end

    local compact = specId:gsub("[%s_%-]", "")
    for _, opt in ipairs(options) do
        local optCompact = opt.id:gsub("_", "")
        local labelCompact = opt.label:lower():gsub("[%s_%-]", "")
        if optCompact == compact or labelCompact == compact then
            return opt.id
        end
    end

    return specId
end

function GQ.Spec:SetSelectedSpec(specId, classFile)
    classFile = classFile or GQ:GetEffectiveClass()
    local options = self:GetOptions(classFile)
    if not options then
        return false, "This class has no specialization options in GearQuest yet."
    end

    specId = self:ResolveSpecInput(specId, classFile)
    local matched
    for _, opt in ipairs(options) do
        if opt.id == specId then
            matched = opt
            break
        end
    end

    if not matched then
        local names = {}
        for _, opt in ipairs(options) do
            if self:IsSpecSelectable(opt.id, classFile) then
                table.insert(names, opt.id)
            end
        end
        return false, "Unknown spec. Use: " .. table.concat(names, ", ")
    end

    if not self:IsSpecSelectable(matched.id, classFile) then
        return false, matched.label .. " is coming later."
    end

    local previewMode = GQ.IsPreviewEnabled and GQ:IsPreviewEnabled()
    GetSpecStore(previewMode)[classFile] = matched.id

    if GQ.Data and GQ.Data.InvalidateSpecCache then
        GQ.Data:InvalidateSpecCache()
    end

    if GQ.RefreshUI then
        GQ:RefreshUI({ reason = "spec" })
    end

    return true
end

local function GetTalentTabPoints(tab)
    if not GetTalentTabInfo then
        return 0
    end

    local _, _, third, _, fifth = GetTalentTabInfo(tab)
    -- TBC Anniversary / modern Classic: id, name, description, icon, pointsSpent, ...
    -- Legacy Classic: name, icon, pointsSpent, fileName
    return tonumber(fifth) or tonumber(third) or 0
end

function GQ.Spec:DetectSpecFromTalents(classFile)
    local byTab = SPEC_BY_TAB[classFile]
    if not byTab or not GetTalentTabInfo then
        return nil
    end

    local bestTab, bestPoints = nil, 0
    for tab = 1, #byTab do
        local points = GetTalentTabPoints(tab)
        if points > bestPoints then
            bestPoints = points
            bestTab = tab
        end
    end

    if bestTab and bestPoints > 0 then
        return byTab[bestTab]
    end

    return nil
end

function GQ.Spec:GetEffectiveSpec()
    local level = tonumber(GQ:GetEffectiveLevel()) or 0
    if level < self.TALENT_LEVEL then
        return nil
    end

    local classFile = GQ:GetEffectiveClass()
    if not self:HasSpecs(classFile) then
        return nil
    end

    local spec

    local saved = self:GetSavedSpec(classFile)
    if saved and self:IsSpecSelectable(saved, classFile) then
        spec = saved
    end

    if not spec and not GQ:IsPreviewEnabled() then
        local fromTalents = self:DetectSpecFromTalents(classFile)
        if fromTalents and self:IsSpecSelectable(fromTalents, classFile) then
            spec = fromTalents
        end
    end

    if not spec then
        spec = self:GetDefaultSpec(classFile)
    end

    return spec
end

function GQ.Spec:GetSelectedSpecLabel()
    local classFile = GQ:GetEffectiveClass()
    local specId = self:GetEffectiveSpec()
    return self:GetSpecLabel(specId, classFile) or "Specialization"
end
