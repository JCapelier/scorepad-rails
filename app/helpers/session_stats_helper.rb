module SessionStatsHelper
  def format_stat_value(value)
    Rails.logger.debug("format_stat_value called with: #{value.inspect}")
    if value.is_a?(Hash) &&
       (value.key?(:percent) || value.key?('percent')) &&
       (value.key?(:count) || value.key?('count')) &&
       (value.key?(:total) || value.key?('total'))
      percent = value[:percent] || value['percent']
      count   = value[:count]   || value['count']
      total   = value[:total]   || value['total']
      "#{percent}% (#{count}/#{total})"
    else
      value
    end
  end
end
