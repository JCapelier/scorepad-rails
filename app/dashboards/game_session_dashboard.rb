require "administrate/base_dashboard"

class GameSessionDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    ends_at: Field::DateTime,
    game: Field::BelongsTo,
    location: Field::String,
    notes: Field::String,
    number_of_players: Field::Number,
    scoresheet: Field::HasOne,
    session_players: Field::HasMany,
    starts_at: Field::DateTime,
    status: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    ends_at
    game
    location
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    ends_at
    game
    location
    notes
    number_of_players
    scoresheet
    session_players
    starts_at
    status
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    ends_at
    game
    location
    notes
    number_of_players
    scoresheet
    session_players
    starts_at
    status
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how game sessions are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(game_session)
  #   "GameSession ##{game_session.id}"
  # end
end
