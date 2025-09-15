class ScoresheetPolicy < ApplicationPolicy
  def show?
    record.game_session.session_players.exists?(user: user)
  end

  def results?
    record.game_session.session_players.exists?(user: user)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(game_session: :session_players).where(session_players: { user_id: user.id })
    end
  end
end
