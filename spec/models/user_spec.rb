require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:user)).to be_valid
    end

    it "requires a name" do
      user = build(:user, name: nil)

      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    it "requires a unique email" do
      create(:user, email: "caixa@sgm.test")
      user = build(:user, email: "caixa@sgm.test")

      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("has already been taken")
    end

    it "requires a unique cpf" do
      create(:user, cpf: "12345678901")
      user = build(:user, cpf: "12345678901")

      expect(user).not_to be_valid
      expect(user.errors[:cpf]).to include("has already been taken")
    end

    it "requires a role" do
      user = build(:user, role: nil)

      expect(user).not_to be_valid
      expect(user.errors[:role]).to include("can't be blank")
    end

    it "requires a unique jti" do
      existing_user = create(:user)
      user = build(:user, jti: existing_user.jti)

      expect(user).not_to be_valid
      expect(user.errors[:jti]).to include("has already been taken")
    end

    it "generates a jti when it is missing" do
      user = build(:user, jti: nil)

      user.validate

      expect(user.jti).to be_present
    end

    it "requires a password on creation" do
      user = build(:user, password: nil)

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it "requires a password with at least six characters" do
      user = build(:user, password: "12345")

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("is too short (minimum is 6 characters)")
    end

    it "does not allow a future birth date" do
      user = build(:user, birth_date: 1.day.from_now.to_date)

      expect(user).not_to be_valid
      expect(user.errors[:birth_date]).to include("can't be in the future")
    end

    it "requires active to be boolean" do
      user = build(:user, active: nil)

      expect(user).not_to be_valid
      expect(user.errors[:active]).to include("is not included in the list")
    end
  end

  describe "roles" do
    it "defines the expected roles" do
      expect(described_class.roles).to eq(
        "admin" => 0,
        "manager" => 1,
        "cashier" => 2
      )
    end

    it "builds users for each profile" do
      expect(build(:user, :admin)).to be_admin
      expect(build(:user, :manager)).to be_manager
      expect(build(:user, :cashier)).to be_cashier
    end
  end

  describe "authentication status" do
    it "allows active users to authenticate" do
      user = build(:user, active: true)

      expect(user.active_for_authentication?).to be(true)
    end

    it "prevents inactive users from authenticating" do
      user = build(:user, :inactive)

      expect(user.active_for_authentication?).to be(false)
      expect(user.inactive_message).to eq(:inactive)
    end
  end
end
