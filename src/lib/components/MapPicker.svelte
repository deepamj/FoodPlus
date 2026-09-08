<script>
  import { onMount, onDestroy } from 'svelte'
  export let lat = 28.6139   // default: New Delhi
  export let lng = 77.2090
  export let onPick = (lat, lng) => {}

  let mapEl
  let map, marker, L

  onMount(async () => {
    // Dynamic import so SSR-safe (no SSR here but good practice)
    L = (await import('leaflet')).default
    // Inject Leaflet CSS
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

  onDestroy(() => { if (map) map.remove() })
</script>

<div class="map-container" bind:this={mapEl}></div>
