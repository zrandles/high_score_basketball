import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "tbody" ]

  sort(event) {
    const column = event.currentTarget.dataset.column
    const tbody = this.tbodyTarget
    const rows = Array.from(tbody.querySelectorAll('tr'))

    // Get current sort direction
    const currentDirection = event.currentTarget.dataset.direction || 'asc'
    const newDirection = currentDirection === 'asc' ? 'desc' : 'asc'

    // Update direction
    event.currentTarget.dataset.direction = newDirection

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

    // Clear and re-append rows
    tbody.innerHTML = ''
    rows.forEach(row => tbody.appendChild(row))
  }

  getCellValue(row, column) {
    const cell = row.querySelector(`td[data-value]`)
    const cells = row.querySelectorAll('td[data-value]')

    // Find the right cell based on column
    const columnIndex = {
      'rank': 0,
      'player': 1,
      'team': 2,
      'avg_high': 3,
      'weeks': 4,
      'variance': 5,
      'peak': 6,
      'floor': 7
    }

    const targetCell = cells[columnIndex[column]]
    if (!targetCell) return ''

    const value = targetCell.dataset.value

    // Try to parse as number
    const numValue = parseFloat(value)
    return isNaN(numValue) ? value : numValue
  }
}
