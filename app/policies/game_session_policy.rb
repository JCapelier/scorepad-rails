class GameSessionPolicy < ApplicationPolicy
  def new?
    true
  end

  def create?
    true
  end

  def destroy?
    record.session_players.exists?(user: user)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:session_players).where(session_players: { user_id: user.id })
    end
  end
end
