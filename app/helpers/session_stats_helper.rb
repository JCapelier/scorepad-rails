module SessionStatsHelper
  def format_stat_value(value, player = nil)
    if value.is_a?(Hash) &&
       (value.key?(:percent) || value.key?('percent')) &&
       (value.key?(:count) || value.key?('count')) &&
       (value.key?(:total) || value.key?('total'))
      percent = value[:percent] || value['percent']
      count   = value[:count]   || value['count']
      total   = value[:total]   || value['total']
      "#{percent}% (#{count}/#{total})"
    elsif value.is_a?(Hash) && player
      value[player.display_name] || "-"
    else
      value
    end
  end
end
