import { Controller } from "@hotwired/stimulus"

/**
 * Waiver Wire Filter Controller
 *
 * Features:
 * - Search by player name
 * - Filter by position, trending status, min games played
 * - Sort by any column
 * - Advanced filters with percentile sliders
 */
export default class extends Controller {
  static targets = ["modal", "filterBar", "table", "tbody", "resultCount", "hiddenList", "shownList", "featuredList", "searchInput"]

  connect() {
    console.log('Waiver Wire controller connected!')
    this.searchTerm = ''
    this.loadPlayers()
    this.loadPercentiles()
    this.initializeColumns()
    this.loadState()
    this.applyFilters()
    this.renderModal()
    this.renderFilterBar()
  }

  /**
   * Load player data from embedded JSON
   */
  loadPlayers() {
    try {
      const dataScript = document.getElementById('players-data')
      if (!dataScript) {
        console.error('❌ No players-data script tag found')
        this.players = []
        return
      }

      this.players = JSON.parse(dataScript.textContent.trim())
      console.log(`✅ Loaded ${this.players.length} players`)
    } catch (e) {
      console.error('❌ Failed to parse players data:', e)
      this.players = []
    }
  }

  /**
   * Load percentile values for sliders
   */
  loadPercentiles() {
    try {
      const dataScript = document.getElementById('percentile-values')
      if (!dataScript) {
        console.error('❌ No percentile-values script tag found')
        this.percentileValues = {}
        return
      }

      this.percentileValues = JSON.parse(dataScript.textContent.trim())
      console.log(`✅ Loaded percentile values for ${Object.keys(this.percentileValues).length} columns`)
    } catch (e) {
      console.error('❌ Failed to parse percentile values:', e)
      this.percentileValues = {}
    }
  }

  /**
   * Initialize column definitions
   */
  initializeColumns() {
    this.allColumns = [
      { key: 'name', name: 'Player', filterable: false },
      { key: 'position', name: 'Position', filterable: false },
      { key: 'team', name: 'Team', filterable: false },
      { key: 'last_7_days_avg', name: 'Last 7d Avg', filterable: true },
      { key: 'trend_7_days', name: 'Trend %', filterable: true },
      { key: 'last_7_days_high', name: '7d High', filterable: true },
      { key: 'last_7_days_games', name: 'GP (7d)', filterable: true },
      { key: 'avg_score', name: 'Season Avg', filterable: true },
      { key: 'last_14_days_avg', name: '14d Avg', filterable: true },
      { key: 'last_14_days_games', name: 'GP (14d)', filterable: true }
    ]

    // Get all table rows
    this.allRows = Array.from(this.tbodyTarget.querySelectorAll('tr'))
  }

  /**
   * Load saved state from localStorage
   */
  loadState() {
    const saved = localStorage.getItem('waiverWireFilterState')
    if (saved) {
      const state = JSON.parse(saved)
      this.hiddenColumns = state.hidden || []
      this.shownColumns = state.shown || []
      this.featuredColumns = state.featured || {}

      // Ensure all featured columns have a mode
      Object.keys(this.featuredColumns).forEach(key => {
        if (!this.featuredColumns[key].mode) {
          this.featuredColumns[key].mode = 'filter'
        }
      })
    } else {
      // Default: all columns shown
      this.shownColumns = this.allColumns.map(col => col.key)
      this.hiddenColumns = []
      this.featuredColumns = {}
    }
  }

  /**
   * Save state to localStorage
   */
  saveState() {
    const state = {
      hidden: this.hiddenColumns,
      shown: this.shownColumns,
      featured: this.featuredColumns
    }
    localStorage.setItem('waiverWireFilterState', JSON.stringify(state))
  }

  /**
   * Handle search input
   */
  handleSearch(event) {
    this.searchTerm = event.target.value.toLowerCase().trim()
    this.applyFilters()
  }

  /**
   * Apply all filters
   */
  applyFilters() {
    const featuredCols = Object.keys(this.featuredColumns)

    // No filters - show all
    if (featuredCols.length === 0 && !this.searchTerm) {
      this.allRows.forEach(row => {
        row.style.display = ''
      })
      this.updateResultCount(this.allRows.length)
      return
    }

    // Calculate percentiles for featured columns
    const percentiles = this.calculatePercentiles(featuredCols)
    let visibleCount = 0

    this.allRows.forEach(row => {
      // Search filter
      if (this.searchTerm) {
        const playerName = row.dataset.playerName || ''
        if (!playerName.includes(this.searchTerm)) {
          row.style.display = 'none'
          return
        }
      }

      // Percentile filters
      let passesFilters = true
      for (const colKey of featuredCols) {
        const filter = this.featuredColumns[colKey]
        const value = parseFloat(row.dataset[this.camelCase(colKey)])

        if (isNaN(value)) {
          passesFilters = false
          break
        }

        const percentile = this.getPercentile(value, percentiles[colKey])
        if (percentile < filter.min || percentile > filter.max) {
          passesFilters = false
          break
        }
      }

      if (passesFilters) {
        row.style.display = ''
        visibleCount++
      } else {
        row.style.display = 'none'
      }
    })

    this.updateResultCount(visibleCount)
  }

  /**
   * Convert snake_case to camelCase for dataset attributes
   */
  camelCase(str) {
    return str.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
  }

  /**
   * Calculate percentiles for columns
   */
  calculatePercentiles(columns) {
    const percentiles = {}

    columns.forEach(colKey => {
      const values = []

      this.allRows.forEach(row => {
        const value = parseFloat(row.dataset[this.camelCase(colKey)])
        if (!isNaN(value)) {
          values.push(value)
        }
      })

      values.sort((a, b) => a - b)
      percentiles[colKey] = values
    })

    return percentiles
  }

  /**
   * Get percentile rank for a value
   */
  getPercentile(value, sortedValues) {
    if (sortedValues.length === 0) return 0

    let count = 0
    for (const v of sortedValues) {
      if (v <= value) count++
      else break
    }

    return Math.round((count / sortedValues.length) * 100)
  }

  /**
   * Update result count
   */
  updateResultCount(count) {
    if (this.hasResultCountTarget) {
      this.resultCountTarget.textContent = `Showing ${count} of ${this.allRows.length} players`
    }
  }

  /**
   * Render modal
   */
  renderModal() {
    const hiddenCols = this.allColumns.filter(c => this.hiddenColumns.includes(c.key))
    const shownCols = this.allColumns.filter(c => this.shownColumns.includes(c.key) && !this.featuredColumns[c.key])
    const featuredCols = this.allColumns.filter(c => this.featuredColumns[c.key])

    this.hiddenListTarget.innerHTML = this.renderColumnList(hiddenCols, 'hidden')
    this.shownListTarget.innerHTML = this.renderColumnList(shownCols, 'shown')
    this.featuredListTarget.innerHTML = this.renderColumnList(featuredCols, 'featured')

    document.getElementById('hidden-count').textContent = hiddenCols.length
    document.getElementById('shown-count').textContent = shownCols.length
    document.getElementById('featured-count').textContent = featuredCols.length
  }

  /**
   * Render column list for modal
   */
  renderColumnList(columns, state) {
    if (columns.length === 0) {
      return '<p class="text-sm text-gray-400 italic p-4">No columns</p>'
    }

    return columns.map(col => {
      let buttons = ''

      if (state === 'hidden') {
        buttons = `<span class="text-gray-400 hover:text-gray-600 cursor-pointer" data-action="click->waiver-wire#moveToShown" data-column="${col.key}">→</span>`
      } else if (state === 'shown') {
        buttons = `
          <div class="flex gap-2">
            <span class="text-gray-400 hover:text-gray-600 cursor-pointer" data-action="click->waiver-wire#moveToHidden" data-column="${col.key}" title="Hide column">←</span>
            ${col.filterable ? `<span class="text-gray-400 hover:text-blue-600 cursor-pointer" data-action="click->waiver-wire#moveToFeatured" data-column="${col.key}" title="Add filter">★</span>` : ''}
          </div>
        `
      } else {
        buttons = `<span class="text-gray-400 hover:text-red-600 cursor-pointer" data-action="click->waiver-wire#moveToShown" data-column="${col.key}" title="Remove filter">✕</span>`
      }

      return `
        <div class="flex items-center justify-between px-3 py-2 hover:bg-gray-50 rounded">
          <span class="text-sm text-gray-700">${col.name}</span>
          ${buttons}
        </div>
      `
    }).join('')
  }

  /**
   * Render filter bar with sliders
   */
  renderFilterBar() {
    const featuredCols = Object.keys(this.featuredColumns)

    if (featuredCols.length === 0) {
      this.filterBarTarget.classList.add('hidden')
      return
    }

    this.filterBarTarget.classList.remove('hidden')

    const html = `
      <div class="bg-gray-50 border-b border-gray-200 p-4 mb-4 rounded-lg">
        <div class="flex justify-between items-center mb-3">
          <h3 class="text-sm font-semibold text-gray-700">
            Active Filters (${featuredCols.length})
          </h3>
          <div class="flex gap-2">
            <button data-action="click->waiver-wire#clearAllFilters"
                    class="text-sm text-blue-600 hover:text-blue-800">Clear All</button>
          </div>
        </div>
        <div class="space-y-3">
          ${featuredCols.map(key => this.renderSlider(key)).join('')}
        </div>
      </div>
    `

    this.filterBarTarget.innerHTML = html
  }

  /**
   * Render a slider for a column
   */
  renderSlider(columnKey) {
    const column = this.allColumns.find(c => c.key === columnKey)
    const filter = this.featuredColumns[columnKey]
    const valueRange = this.getValueRangeForPercentile(columnKey, filter.min, filter.max)

    const labelText = valueRange
      ? `${filter.min}th-${filter.max}th percentile (${valueRange})`
      : `${filter.min}th-${filter.max}th percentile`

    return `
      <div class="flex items-center gap-4 bg-white p-3 rounded-lg border border-gray-200">
        <div class="flex-shrink-0 w-32">
          <span class="text-sm font-medium text-gray-700">${column.name}</span>
        </div>
        <div class="flex-grow">
          <div class="relative h-6">
            <input type="range"
                   min="0" max="100"
                   value="${filter.min}"
                   data-column="${columnKey}"
                   data-handle="min"
                   data-action="input->waiver-wire#updateSlider"
                   class="absolute w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer"
                   style="pointer-events: auto;">
            <input type="range"
                   min="0" max="100"
                   value="${filter.max}"
                   data-column="${columnKey}"
                   data-handle="max"
                   data-action="input->waiver-wire#updateSlider"
                   class="absolute w-full h-2 bg-transparent rounded-lg appearance-none cursor-pointer"
                   style="pointer-events: auto;">
          </div>
          <div class="text-xs text-center text-gray-600 mt-1" data-percentile-label="${columnKey}">
            ${labelText}
          </div>
        </div>
        <button data-action="click->waiver-wire#removeFilter"
                data-column="${columnKey}"
                class="flex-shrink-0 text-gray-400 hover:text-red-600 text-lg">✕</button>
      </div>
    `
  }

  /**
   * Update slider values
   */
  updateSlider(event) {
    const column = event.target.dataset.column
    const handle = event.target.dataset.handle
    const value = parseInt(event.target.value)

    if (handle === 'min') {
      this.featuredColumns[column].min = value
      if (value > this.featuredColumns[column].max) {
        this.featuredColumns[column].max = value
      }
    } else {
      this.featuredColumns[column].max = value
      if (value < this.featuredColumns[column].min) {
        this.featuredColumns[column].min = value
      }
    }

    this.updatePercentileLabel(column)
    this.saveState()
    this.applyFilters()
  }

  /**
   * Update percentile label
   */
  updatePercentileLabel(column) {
    const label = this.filterBarTarget.querySelector(`[data-percentile-label="${column}"]`)
    if (label) {
      const filter = this.featuredColumns[column]
      const valueRange = this.getValueRangeForPercentile(column, filter.min, filter.max)

      if (valueRange) {
        label.textContent = `${filter.min}th-${filter.max}th percentile (${valueRange})`
      } else {
        label.textContent = `${filter.min}th-${filter.max}th percentile`
      }
    }
  }

  /**
   * Get value range for percentile range
   */
  getValueRangeForPercentile(column, minPercentile, maxPercentile) {
    const columnData = this.percentileValues[column]
    if (!columnData) return null

    const minValue = this.interpolateValue(columnData, minPercentile)
    const maxValue = this.interpolateValue(columnData, maxPercentile)

    if (minValue === null || maxValue === null) return null

    return `${minValue.toFixed(1)} to ${maxValue.toFixed(1)}`
  }

  /**
   * Interpolate value at percentile
   */
  interpolateValue(columnData, percentile) {
    // Check if we have exact percentile
    if (columnData[percentile.toString()]) {
      return columnData[percentile.toString()]
    }

    // Find bounding percentiles
    const percentiles = Object.keys(columnData).map(Number).sort((a, b) => a - b)
    let lower = 0
    let upper = 100

    for (let i = 0; i < percentiles.length - 1; i++) {
      if (percentiles[i] <= percentile && percentile <= percentiles[i + 1]) {
        lower = percentiles[i]
        upper = percentiles[i + 1]
        break
      }
    }

    const lowerV = columnData[lower.toString()]
    const upperV = columnData[upper.toString()]

    if (lowerV === undefined || upperV === undefined) return null

    const fraction = (percentile - lower) / (upper - lower)
    return lowerV + fraction * (upperV - lowerV)
  }

  // Modal actions
  openModal() {
    this.modalTarget.classList.remove('hidden')
  }

  closeModal() {
    this.modalTarget.classList.add('hidden')
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  moveToShown(event) {
    const column = event.currentTarget.dataset.column
    this.hiddenColumns = this.hiddenColumns.filter(c => c !== column)
    if (!this.shownColumns.includes(column)) {
      this.shownColumns.push(column)
    }
    delete this.featuredColumns[column]
    this.saveState()
    this.renderModal()
  }

  moveToFeatured(event) {
    const column = event.currentTarget.dataset.column
    this.shownColumns = this.shownColumns.filter(c => c !== column)
    this.featuredColumns[column] = { min: 0, max: 100, mode: 'filter' }
    this.saveState()
    this.renderModal()
    this.renderFilterBar()
  }

  moveToHidden(event) {
    const column = event.currentTarget.dataset.column
    this.shownColumns = this.shownColumns.filter(c => c !== column)
    delete this.featuredColumns[column]
    if (!this.hiddenColumns.includes(column)) {
      this.hiddenColumns.push(column)
    }
    this.saveState()
    this.renderModal()
  }

  removeFilter(event) {
    const column = event.currentTarget.dataset.column
    delete this.featuredColumns[column]
    if (!this.shownColumns.includes(column)) {
      this.shownColumns.push(column)
    }
    this.saveState()
    this.renderModal()
    this.renderFilterBar()
    this.applyFilters()
  }

  clearAllFilters() {
    Object.keys(this.featuredColumns).forEach(key => {
      if (!this.shownColumns.includes(key)) {
        this.shownColumns.push(key)
      }
    })
    this.featuredColumns = {}
    this.saveState()
    this.renderModal()
    this.renderFilterBar()
    this.applyFilters()
  }

  saveConfiguration() {
    this.saveState()
    this.applyFilters()
    this.closeModal()
  }

  resetConfiguration() {
    if (confirm('Reset all filter settings to defaults?')) {
      localStorage.removeItem('waiverWireFilterState')
      location.reload()
    }
  }
}
