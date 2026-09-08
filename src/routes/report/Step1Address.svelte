<script>
  import Wordmark from '../../lib/components/Wordmark.svelte'
  import MapPicker from '../../lib/components/MapPicker.svelte'
  import { draft } from '../../lib/stores/draft.js'

  export let onNext = () => {}
  export let onBack = () => {}

  let address = $draft.address
  let lat = $draft.lat || 28.6139
  let lng = $draft.lng || 77.2090

  function handlePick(la, ln) { lat = la; lng = ln }

  function next() {
    if (!address.trim()) { alert('Please enter an address.'); return }
    draft.update(d => ({ ...d, address, lat, lng }))
    onNext()
  }
</script>

<div class="report-page">
  <div class="page-header">
    <div class="page-nav">
      <button class="back-btn" on:click={onBack} aria-label="Go back">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <path d="M19 12H5M12 5l-7 7 7 7"/>
        </svg>
      </button>
      <Wordmark />
    </div>
    <h1 class="page-title">Report surplus</h1>
  </div>

  <!-- Step bar: manual layout matching wireframe -->
  <div class="step-bar">
    <!-- Step 1: active -->
    <div class="step-row active">
      <div class="step-line-col">
        <div class="step-dot"></div>
        <div class="step-connector"></div>
      </div>
      <div style="flex:1">
        <span class="step-label">1. Add an address</span>
        <div class="page-content" style="padding:0;margin-top:10px">
          <MapPicker {lat} {lng} onPick={handlePick} />
          <input
            id="address-input"
            class="input mt-12"
            placeholder="Type your address…"
            bind:value={address}
          />
          <p class="text-muted mt-8" style="font-size:.78rem">
            Drag the pin or click the map to set the exact pickup location.
          </p>
        </div>
      </div>
    </div>
    <!-- Step 2: future -->
    <div class="step-row future">
      <div class="step-line-col">
        <div class="step-dot"></div>
        <div class="step-connector"></div>
      </div>
      <span class="step-label">2. Enter details</span>
    </div>
    <!-- Step 3: future -->
    <div class="step-row future">
      <div class="step-line-col"><div class="step-dot"></div></div>
      <span class="step-label">3. Add photos</span>
    </div>
  </div>

  <div class="bottom-bar">
    <button id="step1-continue" class="btn btn-primary" on:click={next}>Continue</button>
  </div>
</div>

<style>
.report-page { min-height: 100dvh; padding-bottom: 90px; }
</style>
