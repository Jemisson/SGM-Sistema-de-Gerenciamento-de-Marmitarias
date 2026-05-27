require "rails_helper"

RSpec.describe Recipe, type: :model do
  it "is valid with valid attributes" do
    expect(build(:recipe)).to be_valid
  end

  it "requires a product" do
    recipe = build(:recipe, product: nil)

    expect(recipe).not_to be_valid
    expect(recipe.errors[:product]).to include("must exist")
  end

  it "requires a name" do
    recipe = build(:recipe, name: nil)

    expect(recipe).not_to be_valid
    expect(recipe.errors[:name]).to include("can't be blank")
  end

  it "requires active to be boolean" do
    recipe = build(:recipe, active: nil)

    expect(recipe).not_to be_valid
    expect(recipe.errors[:active]).to include("is not included in the list")
  end

  it "requires at least one item" do
    recipe = build(:recipe, items_count: 0)

    expect(recipe).not_to be_valid
    expect(recipe.errors[:recipe_items]).to include("must have at least one item")
  end

  it "does not allow active recipe for inactive product" do
    recipe = build(:recipe, product: create(:product, :inactive))

    expect(recipe).not_to be_valid
    expect(recipe.errors[:product]).to include("must be active")
  end

  it "does not allow more than one active recipe for the same product" do
    product = create(:product)
    create(:recipe, product: product)
    recipe = build(:recipe, product: product)

    expect(recipe).not_to be_valid
    expect(recipe.errors[:product_id]).to include("has already been taken")
  end

  it "allows a new active recipe when the previous one is inactive" do
    product = create(:product)
    create(:recipe, :inactive, product: product)

    expect(build(:recipe, product: product)).to be_valid
  end

  it "does not allow duplicated ingredients in nested items" do
    ingredient = create(:ingredient)
    recipe = build(:recipe, items_count: 0)
    recipe.recipe_items << build(:recipe_item, recipe: recipe, ingredient: ingredient)
    recipe.recipe_items << build(:recipe_item, recipe: recipe, ingredient: ingredient)

    expect(recipe).not_to be_valid
    expect(recipe.errors[:recipe_items]).to include("cannot have duplicated ingredients")
  end
end
