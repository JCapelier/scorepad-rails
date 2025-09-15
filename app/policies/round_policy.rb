class RoundPolicy < ApplicationPolicy
  def update?
    record.scoresheet.game_session.session_players.exists?(user: user)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(scoresheet: { game_session: :session_players })
          .where(session_players: { user_id: user.id })
    end
  end
end
