<script>
  import { supabase } from '../supabase.js'
  export let post    // { id, address, profiles: { org_name, name }, post_items, post_photos }
  export let onClick = () => {}

  let photoUrls = []

  $: {
    photoUrls = (post.post_photos || []).map(p =>
      supabase.storage.from('post-photos').getPublicUrl(p.storage_path).data.publicUrl
    )
  }

  function totalParcels(items) {
    return (items || []).reduce((s, i) => s + (i.available ?? 0), 0)
  }
</script>

<!-- svelte-ignore a11y-click-events-have-key-events -->
<!-- svelte-ignore a11y-no-static-element-interactions -->
<div class="post-card" on:click={onClick} role="button" tabindex="0" on:keypress={e => e.key==='Enter' && onClick()}>
  {#if photoUrls.length > 0}
    <div class="post-card-photos" class:single-layout={photoUrls.length === 1}>
      {#each photoUrls.slice(0, 2) as url, i}
        <img src={url} alt="Food photo {i+1}" loading="lazy" />
      {/each}
    </div>
  {:else}
    <div class="post-card-photos no-photo" style="background:var(--accent-muted);height:160px;display:flex;align-items:center;justify-content:center;">
      <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="var(--accent-light)" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
        <path d="M5 8h14M5 8a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v0a2 2 0 01-2 2M5 8l1 12h12L19 8"/>
      </svg>
    </div>
  {/if}
  <div class="post-card-info">
    <div class="post-card-name">{post.profiles?.org_name || post.profiles?.name || 'Donor'}</div>
    <div class="post-card-parcels">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
        <path d="M5 8h14M5 8a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v0a2 2 0 01-2 2M5 8l1 12h12L19 8"/>
      </svg>
      {totalParcels(post.post_items)} parcels available
    </div>
    <div class="text-muted mt-4" style="font-size:.8rem">{post.address}</div>
  </div>
</div>

<style>
.single-layout { grid-template-columns: 1fr !important; }
</style>
