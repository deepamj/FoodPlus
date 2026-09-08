<script>
  import { onMount } from 'svelte'
  import { supabase } from '../../lib/supabase.js'
  import Wordmark from '../../lib/components/Wordmark.svelte'
  import PostCard from '../../lib/components/PostCard.svelte'

  export let onSelect = (post) => {}
  export let onBack = () => {}

  let posts = []
  let loading = true
  let error = ''

  onMount(async () => {
    const { data, error: e } = await supabase
      .from('posts')
      .select(`
        id, address, lat, lng, status, expires_at, created_at,
        profiles (id, name, org_name),
        post_items (id, name, quantity, available, is_veg),
        post_photos (id, storage_path)
      `)
      .eq('status', 'posted')
      .order('created_at', { ascending: false })
    loading = false
    if (e) { error = e.message; return }
    posts = data || []
  })
</script>

<div class="browse-page">
  <div class="page-header" style="padding-bottom:16px">
    <div class="page-nav">
      <button class="back-btn" on:click={onBack} aria-label="Go back">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <path d="M19 12H5M12 5l-7 7 7 7"/>
        </svg>
      </button>
      <Wordmark />
    </div>
    <h1 class="page-title">Collect Surplus</h1>
  </div>

  <div class="page-content" style="padding-top:16px;padding-bottom:32px">
    {#if loading}
      <div class="spinner"></div>
    {:else if error}
      <div class="error-msg">{error}</div>
    {:else if posts.length === 0}
      <div class="text-center text-muted" style="margin-top:60px">
        <div style="color:var(--accent-light);margin-bottom:12px">
          <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
            <path d="M5 8h14M5 8a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v0a2 2 0 01-2 2M5 8l1 12h12L19 8"/>
          </svg>
        </div>
        <p>No surplus posts available right now.<br>Check back soon!</p>
      </div>
    {:else}
      {#each posts as post}
        <PostCard {post} onClick={() => onSelect(post)} />
      {/each}
    {/if}
  </div>
</div>

<style>
.browse-page { min-height: 100dvh; }
</style>
