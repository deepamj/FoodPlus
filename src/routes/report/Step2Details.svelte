<script>
  import Wordmark from '../../lib/components/Wordmark.svelte'
  import FoodItemRow from '../../lib/components/FoodItemRow.svelte'
  import { draft } from '../../lib/stores/draft.js'

  export let onNext = () => {}
  export let onBack = () => {}
  export let onHome = null

  // Deep-clone items from store so we can mutate locally
  let items = $draft.items.map(i => ({ ...i }))
  let expires_at = $draft.expires_at || ''

  function addItem() {
    items = [...items, { name: '', quantity: '', is_veg: true }]
  }
  function removeItem(i) {
    items = items.filter((_, idx) => idx !== i)
  }

  function next() {
    const valid = items.every(it => it.name.trim() && Number(it.quantity) > 0)
    if (!valid) { alert('Please fill in all food items with a name and quantity > 0.'); return }
    draft.update(d => ({ ...d, items: items.map(i => ({ ...i })), expires_at }))
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
      <Wordmark onClick={onHome} />
    </div>
    <h1 class="page-title">Report surplus</h1>
  </div>

  <div class="step-bar">
    <!-- Step 1: done -->
    <div class="step-row done">
      <div class="step-line-col">
        <div class="step-dot"></div>
        <div class="step-connector"></div>
      </div>
      <span class="step-label">1. Add an address</span>
    </div>
    <!-- Step 2: active -->
    <div class="step-row active">
      <div class="step-line-col">
        <div class="step-dot"></div>
        <div class="step-connector"></div>
      </div>
      <div style="flex:1">
        <span class="step-label">2. Enter details</span>
        <div style="margin-top:12px">
          {#each items as item, i}
            <FoodItemRow
              bind:item={items[i]}
              canRemove={items.length > 1}
              onRemove={() => removeItem(i)}
            />
          {/each}
          <button type="button" class="btn-add-more mt-8" on:click={addItem}>
            <span>⊕</span> Add More
          </button>

          <div style="margin-top:16px">
            <label for="expires-at" style="font-size:.82rem;font-weight:600;color:var(--text-muted)">
              Available until (optional)
            </label>
            <input id="expires-at" class="input mt-4" type="datetime-local" bind:value={expires_at} />
          </div>
        </div>
      </div>
    </div>
    <!-- Step 3: future -->
    <div class="step-row future">
      <div class="step-line-col"><div class="step-dot"></div></div>
      <span class="step-label">3. Add photos</span>
    </div>
  </div>

  <div class="bottom-bar">
    <button id="step2-continue" class="btn btn-primary" on:click={next}>Continue</button>
  </div>
</div>

<style>
.report-page { min-height: 100dvh; padding-bottom: 90px; }
</style>
