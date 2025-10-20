module PlayersHelper
  def variance_class(variance)
    if variance >= 150
      { class: 'bg-red-100 text-red-800', label: 'High' }
    elsif variance >= 80
      { class: 'bg-yellow-100 text-yellow-800', label: 'Med' }
    else
      { class: 'bg-green-100 text-green-800', label: 'Low' }
    end
  end
end
