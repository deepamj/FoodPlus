<script>
  import { supabase } from '../../lib/supabase.js'
  import { authStore } from '../../lib/stores/auth.js'
  import Wordmark from '../../lib/components/Wordmark.svelte'

  export let post   // full post object from Browse
  export let onDone = () => {}
  export let onBack = () => {}
  export let onHome = null

  // quantities[item.id] = number user wants to claim
  let quantities = Object.fromEntries((post.post_items || []).map(item => [item.id, 0]))

  let loading = false
  let error   = ''
  let success = false

  function increment(id, available) {
    if (quantities[id] < available) quantities[id]++
    quantities = { ...quantities }
  }
  function decrement(id) {
    if (quantities[id] > 0) quantities[id]--
    quantities = { ...quantities }
  }

  function totalSelected() {
    return Object.values(quantities).reduce((s, v) => s + v, 0)
  }

  async function confirm() {
    if (totalSelected() === 0) { error = 'Select at least one parcel to claim.'; return }
    loading = true; error = ''
    const user = $authStore.user
    if (!user) { error = 'Not logged in'; loading = false; return }

    // Build the quantities object with only items that have qty > 0
    const payload = {}
    for (const [id, qty] of Object.entries(quantities)) {
      if (qty > 0) payload[id] = qty
    }

    const { error: e } = await supabase.rpc('claim_post', {
      p_post_id:    post.id,
      p_ngo_id:     user.id,
      p_quantities: payload
    })
    loading = false
    if (e) { error = e.message; return }
    success = true
  }

  function totalAvailable(items) {
    return (items || []).reduce((s, i) => s + (i.available ?? 0), 0)
  }

  $: photoUrls = (post.post_photos || []).map(p =>
    supabase.storage.from('post-photos').getPublicUrl(p.storage_path).data.publicUrl
  )
</script>

<div class="claim-page">
  <div class="page-header" style="padding-bottom:16px">
    <div class="page-nav">
      <button class="back-btn" on:click={onBack} aria-label="Go back">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <path d="M19 12H5M12 5l-7 7 7 7"/>
        </svg>
      </button>
      <Wordmark onClick={onHome} />
    </div>
    <h1 class="page-title">{post.profiles?.org_name || post.profiles?.name || 'Donor'}</h1>
    <p class="text-muted" style="font-size:.85rem;margin-top:4px">{post.address}</p>
  </div>

  {#if success}
    <div class="page-content" style="display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:60dvh;gap:16px">
      <div style="width:64px;height:64px;border-radius:50%;background:var(--veg-bg);display:flex;align-items:center;justify-content:center">
        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="var(--veg)" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <path d="M20 6L9 17l-5-5"/>
        </svg>
      </div>
      <h2 style="font-family:'Playfair Display',serif;font-size:1.4rem;color:var(--accent)">Claimed!</h2>
      <p class="text-muted text-center" style="font-size:.9rem">
        The donor has been notified. Coordinate pickup at the address above.
      </p>
      <button class="btn btn-primary mt-16" on:click={onDone}>Back to listings</button>
    </div>
  {:else}
    <!-- Photos -->
    {#if photoUrls.length > 0}
      <div class="post-card-photos" style="height:200px;display:grid;grid-template-columns:{photoUrls.length > 1 ? '1fr 1fr' : '1fr'}">
        {#each photoUrls.slice(0, 2) as url, i}
          <img src={url} alt="Food photo {i+1}" style="width:100%;height:100%;object-fit:cover" />
        {/each}
      </div>
    {/if}

    <div class="page-content" style="padding-top:16px;padding-bottom:100px">
      <p style="font-size:.8rem;font-weight:600;color:var(--text-muted);margin-bottom:12px">
        {totalAvailable(post.post_items)} parcels total · select how many to claim
      </p>

      {#if error}
        <div class="error-msg mt-8 mb-12">{error}</div>
      {/if}

      {#each post.post_items as item}
        <div class="claim-item-row">
          <div>
            <div class="claim-item-name">
              <span class="veg-dot" class:is-veg={item.is_veg} class:is-nonveg={!item.is_veg}></span>
              {item.name}
            </div>
            <div class="claim-item-meta">{item.available} of {item.quantity} available</div>
          </div>
          <div class="qty-control">
            <button
              class="qty-btn"
              on:click={() => decrement(item.id)}
              disabled={quantities[item.id] <= 0}
              aria-label="Decrease quantity"
            >−</button>
            <span class="qty-value">{quantities[item.id]}</span>
            <button
              class="qty-btn"
              on:click={() => increment(item.id, item.available)}
              disabled={quantities[item.id] >= item.available}
              aria-label="Increase quantity"
            >+</button>
          </div>
        </div>
      {/each}
    </div>

    <div class="bottom-bar">
      <button
        id="btn-confirm-claim"
        class="btn btn-primary"
        on:click={confirm}
        disabled={loading || totalSelected() === 0}
      >
        {loading ? 'Confirming…' : `Confirm claim (${totalSelected()} parcel${totalSelected() !== 1 ? 's' : ''})`}
      </button>
    </div>
  {/if}
</div>

<style>
.claim-page { min-height: 100dvh; }
.mb-12 { margin-bottom: 12px; }
</style>
