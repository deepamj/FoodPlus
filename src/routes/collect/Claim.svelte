<script>
  import { onMount } from 'svelte'
  import { supabase } from '../../lib/supabase.js'
  import { authStore } from '../../lib/stores/auth.js'
  import Wordmark from '../../lib/components/Wordmark.svelte'

  let { params = {}, onDone = () => {}, onBack = () => {}, onHome = null } = $props()

  let post = $state(null)
  let loading = $state(true)

  // quantities[item.id] = number user wants to claim
  let quantities = $state({})

  let error   = $state('')
  let success = $state(false)
  let submitting = $state(false)

  onMount(async () => {
    const { data, error: e } = await supabase
      .from('posts')
      .select(`
        id, address, lat, lng, status, expires_at, created_at,
        profiles (id, name, org_name),
        post_items (id, name, quantity, available, is_veg),
        post_photos (id, storage_path)
      `)
      .eq('id', params.id)
      .single()
    loading = false
    if (e || !data) { error = e?.message || 'Post no longer available'; return }
    post = data
    quantities = Object.fromEntries(data.post_items.map(item => [item.id, 0]))
  })

  function increment(id, available) {
    if (quantities[id] < available) quantities[id]++
    quantities = { ...quantities }
  }
  function decrement(id) {
    if (quantities[id] > 0) quantities[id]--
    quantities = { ...quantities }
  }

  let totalSelectedCount = $derived.by(getTotalSelected)

  function getTotalSelected() {
    return Object.values(quantities).reduce((s, v) => s + v, 0)
  }

  async function confirm() {
    if (getTotalSelected() === 0) { error = 'Select at least one parcel to claim.'; return }
    submitting = true; error = ''
    const user = $authStore.user
    if (!user) { error = 'Not logged in'; submitting = false; return }

    const payload = {}
    for (const [id, qty] of Object.entries(quantities)) {
      if (qty > 0) payload[id] = qty
    }

    const { error: e } = await supabase.rpc('claim_post', {
      p_post_id:    params.id,
      p_ngo_id:     user.id,
      p_quantities: payload
    })
    submitting = false
    if (e) { error = e.message; return }
    success = true
  }

  function totalAvailable(items) {
    return (items || []).reduce((s, i) => s + (i.available ?? 0), 0)
  }

  let photoUrls = $derived((post?.post_photos || []).map(p =>
    supabase.storage.from('post-photos').getPublicUrl(p.storage_path).data.publicUrl
  ))
</script>

<div class="claim-page">
  {#if loading}
    <div class="spinner" style="margin-top:40vh"></div>
  {:else if !post}
    <div class="page-header" style="padding-bottom:16px">
      <div class="page-nav">
        <button class="back-btn" on:click={onBack} aria-label="Go back">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <path d="M19 12H5M12 5l-7 7 7 7"/>
          </svg>
        </button>
        <Wordmark onClick={onHome} />
      </div>
    </div>
    <div class="page-content" style="padding-top:16px">
      <div class="error-msg">{error}</div>
      <button class="btn btn-primary mt-8" on:click={onBack}>Back to listings</button>
    </div>

  {:else}
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
          disabled={submitting || totalSelectedCount === 0}
        >
          {submitting ? 'Confirming…' : `Confirm claim (${getTotalSelected()} parcel${getTotalSelected() !== 1 ? 's' : ''})`}
        </button>
      </div>
    {/if}
  {/if}
</div>

<style>
.claim-page { min-height: 100dvh; }
.mb-12 { margin-bottom: 12px; }
</style>
