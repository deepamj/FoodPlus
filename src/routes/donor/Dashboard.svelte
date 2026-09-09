<script>
  import { onMount } from 'svelte'
  import { supabase } from '../../lib/supabase.js'
  import { authStore } from '../../lib/stores/auth.js'
  import Wordmark from '../../lib/components/Wordmark.svelte'

  export let onNewPost = () => {}
  export let onLogout  = () => {}
  export let onHome = null

  let posts   = []
  let loading = true
  let error   = ''
  let markingId = null

  onMount(loadPosts)

  async function loadPosts() {
    loading = true
    const user = $authStore.user
    if (!user) return
    const { data, error: e } = await supabase
      .from('posts')
      .select(`
        id, address, status, expires_at, created_at,
        post_items (id, name, quantity, available, is_veg),
        claims (id, ngo_id, quantities, claimed_at,
          profiles:ngo_id (name, org_name)
        )
      `)
      .eq('donor_id', user.id)
      .order('created_at', { ascending: false })
    loading = false
    if (e) { error = e.message; return }
    posts = data || []
  }

  function claimedParcels(post) {
    return (post.claims || []).reduce(
      (s, c) => s + Object.values(c.quantities || {}).reduce((a, q) => a + q, 0), 0)
  }
  function totalParcels(items) {
    return (items || []).reduce((s, i) => s + (i.quantity ?? 0), 0)
  }

  async function markCollected(post) {
    const remain = totalParcels(post.post_items) - claimedParcels(post)
    if (remain > 0) {
      const ok = confirm(`${remain} parcel${remain !== 1 ? 's' : ''} remain unclaimed. Marking as collected removes this post from the feed. Continue?`)
      if (!ok) return
    }
    markingId = post.id
    const { error: e } = await supabase
      .from('posts')
      .update({ status: 'collected' })
      .eq('id', post.id)
    markingId = null
    if (e) { alert(e.message); return }
    posts = posts.map(p => p.id === post.id ? { ...p, status: 'collected' } : p)
  }

  async function logout() {
    await supabase.auth.signOut()
    onLogout()
  }

  function statusClass(s) {
    if (s === 'posted')    return 'status-posted'
    if (s === 'claimed')   return 'status-claimed'
    if (s === 'collected') return 'status-collected'
    return ''
  }
</script>

<div class="dash-page">
  <div class="page-header" style="padding-bottom:16px">
    <div style="display:flex;align-items:center;justify-content:space-between">
      <Wordmark onClick={onHome} />
      <button class="btn btn-ghost btn-sm" on:click={logout}>Log out</button>
    </div>
    <h1 class="page-title">My surplus posts</h1>
  </div>

  <div class="page-content" style="padding-top:12px;padding-bottom:110px">
    {#if loading}
      <div class="spinner"></div>
    {:else if error}
      <div class="error-msg">{error}</div>
    {:else if posts.length === 0}
      <div class="text-center text-muted" style="margin-top:60px">
        <div style="color:var(--accent-light);margin-bottom:12px">
          <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
            <path d="M21 16V8a2 2 0 00-1-1.73l-7-4a2 2 0 00-2 0l-7 4A2 2 0 003 8v8a2 2 0 001 1.73l7 4a2 2 0 002 0l7-4A2 2 0 0021 16z"/>
            <polyline points="3.27 6.96 12 12.01 20.73 6.96"/>
            <line x1="12" y1="22.08" x2="12" y2="12"/>
          </svg>
        </div>
        <p>No posts yet.<br>Report your first surplus!</p>
      </div>
    {:else}
      {#each posts as post}
        <div class="dash-post-card">
          <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:8px">
            <div style="flex:1">
              <div style="display:flex;align-items:center;gap:8px;flex-wrap:wrap">
                <span class="status-badge {statusClass(post.status)}">{post.status}</span>
                <span style="font-size:.78rem;color:var(--text-muted)">
                  {new Date(post.created_at).toLocaleDateString()}
                </span>
              </div>
              <p class="dash-post-address">{post.address}</p>
            </div>
          </div>

          <div class="dash-post-items">
            {#each post.post_items as item}
              <span class="item-chip {item.is_veg ? 'veg' : 'nonveg'}">
                <span class="veg-dot" class:is-veg={item.is_veg} class:is-nonveg={!item.is_veg}></span>
                {item.name} × {item.available}/{item.quantity}
              </span>
            {/each}
          </div>

          {#if post.status !== 'collected' && post.claims?.length > 0}
            <div style="background:var(--accent-muted);border-radius:var(--radius-xs);padding:10px;font-size:.82rem;margin-top:8px">
              <strong>Claimed by:</strong> {post.claims[0].profiles?.org_name || post.claims[0].profiles?.name || 'NGO'}
              <br>
              <span>{claimedParcels(post)} of {totalParcels(post.post_items)} parcels claimed</span>
              <button
                class="btn btn-primary btn-sm mt-8"
                style="width:auto;display:inline-flex;align-items:center;gap:6px"
                on:click={() => markCollected(post)}
                disabled={markingId === post.id}
              >
                {#if markingId !== post.id}
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>
                {/if}
                {markingId === post.id ? 'Updating…' : 'Mark as collected'}
              </button>
            </div>
          {/if}

          {#if post.status === 'collected'}
            <p style="font-size:.8rem;color:var(--veg);font-weight:600;margin-top:8px;display:flex;align-items:center;gap:4px">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>
              Collected — thank you for reducing food waste!
            </p>
          {/if}
        </div>
      {/each}
    {/if}
  </div>

  <div class="bottom-bar">
    <button id="btn-new-post" class="btn btn-primary" on:click={onNewPost}>+ Report new surplus</button>
  </div>
</div>

<style>
.dash-page { min-height: 100dvh; }
</style>
