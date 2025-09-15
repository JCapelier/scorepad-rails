class UserPolicy < ApplicationPolicy
  def show?
    record == user
  end

  def autocomplete?
    true
  end

  def update?
    record == user
  end
end
