<script>
  import { onMount, onDestroy } from 'svelte'
  export let lat = 28.6139
  export let lng = 77.2090
  export let onPick = (lat, lng, label) => {}

  let mapEl
  let map, marker, L
  let query = ''
  let searching = false
  let searchError = ''

  onMount(async () => {
    L = (await import('leaflet')).default
    if (!document.querySelector('#leaflet-css')) {
      const link = document.createElement('link')
      link.id = 'leaflet-css'
      link.rel = 'stylesheet'
      link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css'
      document.head.appendChild(link)
    }
    map = L.map(mapEl).setView([lat, lng], 14)
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© OpenStreetMap contributors'
    }).addTo(map)
    marker = L.marker([lat, lng], { draggable: true }).addTo(map)
    marker.on('dragend', (e) => {
      const { lat: la, lng: ln } = e.target.getLatLng()
      lat = la; lng = ln
      onPick(la, ln)
    })
    map.on('click', (e) => {
      marker.setLatLng(e.latlng)
      lat = e.latlng.lat; lng = e.latlng.lng
      onPick(lat, lng)
    })
  })

  async function search() {
    if (!query.trim()) return
    searching = true; searchError = ''
    try {
      const res = await fetch(
        `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&limit=1`
      )
      const results = await res.json()
      if (!results.length) { searchError = 'No location found. Try a different search.'; return }
      const { lat: la, lon: ln, display_name } = results[0]
      lat = parseFloat(la); lng = parseFloat(ln)
      map.setView([lat, lng], 16)
      marker.setLatLng([lat, lng])
      onPick(lat, lng, display_name)
    } catch (e) {
      searchError = 'Search failed. Try again.'
    } finally {
      searching = false
    }
  }

  onDestroy(() => { if (map) map.remove() })
</script>

<div class="map-search-row">
  <input
    class="input"
    placeholder="Search for an address or place…"
    bind:value={query}
    on:keydown={(e) => e.key === 'Enter' && search()}
  />
  <button type="button" class="btn btn-secondary btn-sm" on:click={search} disabled={searching}>
    {searching ? '…' : 'Search'}
  </button>
</div>
{#if searchError}
  <p class="text-muted" style="font-size:.78rem;color:var(--non-veg);margin-top:4px">{searchError}</p>
{/if}
<div class="map-container mt-8" bind:this={mapEl}></div>

<style>
  .map-search-row { display: flex; gap: 8px; }
  .map-search-row .input { flex: 1; }
</style>