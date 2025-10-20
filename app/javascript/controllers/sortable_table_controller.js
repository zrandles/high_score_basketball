import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "tbody" ]

  sort(event) {
    const column = event.currentTarget.dataset.column
    const tbody = this.tbodyTarget
    const rows = Array.from(tbody.querySelectorAll('tr'))

    // Get current sort direction
    const currentDirection = event.currentTarget.dataset.direction || 'desc'
    const newDirection = currentDirection === 'asc' ? 'desc' : 'asc'

    // Clear all sort indicators
    this.element.querySelectorAll('th[data-column]').forEach(th => {
      th.dataset.direction = ''
      th.classList.remove('bg-blue-200', 'bg-gray-300')
      // Update arrow icons to default
      const svg = th.querySelector('svg')
      if (svg) {
        svg.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4"/>'
      }
    })

    // Update current header
    event.currentTarget.dataset.direction = newDirection

    // Add active highlight
    if (event.currentTarget.classList.contains('border-l-4')) {
      // Draft value metrics column
      event.currentTarget.classList.add('bg-blue-200')
    } else {
      // Other columns
      event.currentTarget.classList.add('bg-gray-300')
    }

    // Update sort arrow
    const svg = event.currentTarget.querySelector('svg')
    if (svg) {
      if (newDirection === 'asc') {
        svg.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 15l7-7 7 7"/>'
      } else {
        svg.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M19 9l-7 7-7-7"/>'
      }
    }

    // Sort rows
    rows.sort((a, b) => {
      const aValue = this.getCellValue(a, column)
      const bValue = this.getCellValue(b, column)

      if (newDirection === 'asc') {
        return aValue > bValue ? 1 : -1
      } else {
        return aValue < bValue ? 1 : -1
      }
    })

    // Clear and re-append rows with updated striping
    tbody.innerHTML = ''
    rows.forEach((row, index) => {
      // Update row background based on new position
      const isEven = index % 2 === 0
      const bgClass = isEven ? 'bg-white' : 'bg-gradient-to-r from-slate-50/30 to-blue-50/20'

      row.className = `${bgClass} hover:bg-gradient-to-r hover:from-blue-100/50 hover:to-indigo-100/30 cursor-pointer transition-all duration-150 border-b border-gray-100 group`

      // Update sticky cell background
      const stickyCell = row.querySelector('td.sticky')
      if (stickyCell) {
        stickyCell.className = `sticky left-0 z-10 ${bgClass} group-hover:bg-gradient-to-r group-hover:from-blue-100/50 group-hover:to-transparent px-2 sm:px-3 py-3 sm:py-4 whitespace-nowrap`
      }

      tbody.appendChild(row)
    })
  }

  getCellValue(row, column) {
    const cell = row.querySelector(`td[data-value]`)
    const cells = row.querySelectorAll('td[data-value]')

    // Find the right cell based on column
    // Must match the exact order in the HTML table
    const columnIndex = {
      'rank': 0,
      'player': 1,
      'team': 2,
      'variance': 3,
      'differential': 4,
      'avg_high': 5,
      'peak': 6,
      'avg_score': 7,
      'weeks': 8,
      'games_played': 9,
      'floor': 10
    }

    const targetCell = cells[columnIndex[column]]
    if (!targetCell) return ''

    const value = targetCell.dataset.value

    // Try to parse as number
    const numValue = parseFloat(value)
    return isNaN(numValue) ? value : numValue
  }
}
