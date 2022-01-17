local util = require("data-util");
local futil = require("util")

butil = {}
butil.techs = {}
butil.belts = {}

function butil.remove(name, t) 
  local name = name
  log("Found belt entity to remove: ".. name)
  butil.belts[name] = t
end



function butil.remove_belt_prereqs(tech)
  local found = {}
  if not tech.prerequisites then return end
  for i, prerequisite in pairs(tech.prerequisites) do
    if butil.techs[prerequisite] then
      table.insert(found, prerequisite)
    end
  end
  for i, foundp in pairs(found) do
    for j, prerequisite in pairs(tech.prerequisites) do
      if prerequisite == foundp then
        table.remove(tech.prerequisites, j)
      end
    end
  end

  for i, foundp in pairs(found) do
    replacements = get_replacement_prerequisites(foundp)
    if replacements then
      for j, replacement in pairs(replacements) do
        for k, existing in pairs(tech.prerequisites) do
          if replacement == existing then
            goto continue
          end
        end
        table.insert(tech.prerequisites, replacement)
        ::continue::
      end
    end
  end
end

function get_replacement_prerequisites(tech_name)
  local replacements = {}
  local tech = data.raw.technology[tech_name]
  if tech then
    if tech.prerequisites then
      for i, prerequisite in pairs(tech.prerequisites) do
        if butil.techs[prerequisite] then
          local more = get_replacement_prerequisites(prerequisite)
          for j, new_prerequisite in pairs(more) do
            table.insert(replacements, new_prerequisite)
          end
        else
          table.insert(replacements, prerequisite)
        end
      end
    end
  end
  return replacements
end

function butil.replace_belts(ingredients)
  local found = {}
  for i, ingredient in pairs(ingredients) do
    if ingredient then
      if butil.belts[ingredient.name] then table.insert(found, {ingredient.name, ingredient.amount}) end
      if butil.belts[ingredient[1]] then table.insert(found, {ingredient[1], ingredient[2]}) end
    end
  end
  for j, foundi in pairs(found) do
    -- log("found belt "..foundi[1])
    for i, ingredient in pairs(ingredients) do
      -- log(serpent.dump(ingredient))
      if ingredient and (ingredient[1] == foundi[1] or ingredient.name == foundi[1]) then
        -- log("RM ^")
        table.remove(ingredients, i)
      end
    end
  end
  for i, foundi in pairs(found) do
    -- log("doing found belt ".. serpent.dump(foundi))
    local replacements = get_replacement_ingredients(foundi[1])
    local quantity = foundi[2]
    -- log(quantity)
    -- log("replacements "..serpent.dump(replacements))
    for j, new_ingredient in pairs(replacements) do
      doit = true
      for k, existing in pairs(ingredients) do
        -- log("new_ingredient "..serpent.dump(new_ingredient))
        -- log("existing "..serpent.dump(existing))
        if existing[1] and (existing[1] == new_ingredient[1] or existing[1] == new_ingredient.name) then
          -- log("existing "..serpent.dump(existing))
          -- log("new "..serpent.dump(new_ingredient))
          existing[2] = existing[2] + quantity * (new_ingredient[2] and new_ingredient[2] or new_ingredient.amount)
          doit = false
        elseif existing.name and (existing.name == new_ingredient[1] or existing.name == new_ingredient.name) then
          -- log("existing "..serpent.dump(existing))
          -- log("new "..serpent.dump(new_ingredient))
          existing.amount = existing.amount + quantity * (new_ingredient[2] and new_ingredient[2] or new_ingredient.amount)
          doit = false
        end
      end
      if doit then
        if new_ingredient.name then
          -- log(serpent.dump(new_ingredient))
          new_new_ingredient = futil.table.deepcopy(new_ingredient)
          -- log(serpent.dump(new_new_ingredient))
          new_new_ingredient.amount = new_ingredient.amount * quantity
          -- log(serpent.dump(new_new_ingredient))
          table.insert(ingredients, new_new_ingredient)
        elseif new_ingredient[1] then
          table.insert(ingredients, {new_ingredient[1], new_ingredient[2] * quantity})
        end
      end
    end
  end
end

function get_replacement_ingredients(ingredient_name)
  local replacements = {}
  local recipe = data.raw.recipe[ingredient_name]
  if recipe then
    local ingredients = {}
    if recipe.ingredients then
      ingredients = recipe.ingredients
    elseif recipe.normal and recipe.normal.ingredients then
      ingredients = recipe.normal.ingredients
    end
    -- log(serpent.dump(ingredients))
    for i, ingredient in pairs(ingredients) do
      if butil.belts[ingredient[1]] then
        -- log(ingredient[1])
        local more = get_replacement_ingredients(ingredient[1])
        for j, new_ingredient in pairs(more) do
          table.insert(replacements, new_ingredient)
        end
      elseif butil.belts[ingredient.name] then
        -- log(ingredient.name)
        local more = get_replacement_ingredients(ingredient.name)
        for j, new_ingredient in pairs(more) do
          table.insert(replacements, new_ingredient)
        end
      else
        -- log(ingredient.name)
        table.insert(replacements, ingredient)
      end
    end
  end -- if there is no recipe named after the ingredient, just give up
  return replacements
end

function butil.remove_belt_unlocks(tech, recipes) 
  if tech and tech.effects then
    for i, effect in pairs(tech.effects) do
      if effect and effect.type == "unlock-recipe" and recipes[effect.recipe] then
        tech.effects[i] = nil
      end
    end
  end
end
return butil
