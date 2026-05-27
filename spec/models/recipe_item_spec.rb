require "rails_helper"

RSpec.describe RecipeItem, type: :model do
  it "is valid with valid attributes" do
    expect(build(:recipe_item)).to be_valid
  end

  it "requires a recipe" do
    item = build(:recipe_item, recipe: nil)

    expect(item).not_to be_valid
    expect(item.errors[:recipe]).to include("must exist")
  end

  it "requires an ingredient" do
    item = build(:recipe_item, ingredient: nil)

    expect(item).not_to be_valid
    expect(item.errors[:ingredient]).to include("must exist")
  end

  it "requires quantity greater than zero" do
    item = build(:recipe_item, quantity: 0)

    expect(item).not_to be_valid
    expect(item.errors[:quantity]).to include("must be greater than 0")
  end

  it "requires unit" do
    item = build(:recipe_item, unit: nil)

    expect(item).not_to be_valid
    expect(item.errors[:unit]).to include("can't be blank")
  end

  it "does not allow duplicated ingredient in the same recipe" do
    recipe = create(:recipe)
    ingredient = create(:ingredient)
    create(:recipe_item, recipe: recipe, ingredient: ingredient)

    item = build(:recipe_item, recipe: recipe, ingredient: ingredient)

    expect(item).not_to be_valid
    expect(item.errors[:ingredient_id]).to include("has already been taken")
  end
end
