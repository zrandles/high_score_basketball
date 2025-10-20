module PlayersHelper
  def variance_class(variance)
    # HIGH VARIANCE = GOOD for weekly high scoring format
    if variance >= 150
      {
        class: 'bg-green-50 text-green-900',
        border: 'border-green-400',
        badge_class: 'bg-green-200 text-green-900',
        label: 'High'
      }
    elsif variance >= 80
      {
        class: 'bg-yellow-50 text-yellow-900',
        border: 'border-yellow-400',
        badge_class: 'bg-yellow-200 text-yellow-900',
        label: 'Med'
      }
    else
      {
        class: 'bg-red-50 text-red-900',
        border: 'border-red-400',
        badge_class: 'bg-red-200 text-red-900',
        label: 'Low'
      }
    end
  end
end
