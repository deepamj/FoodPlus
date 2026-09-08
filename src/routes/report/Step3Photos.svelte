<script>
  import { supabase } from '../../lib/supabase.js'
  import { authStore } from '../../lib/stores/auth.js'
  import { draft, resetDraft } from '../../lib/stores/draft.js'
  import Wordmark from '../../lib/components/Wordmark.svelte'

  export let onDone = () => {}
  export let onBack = () => {}

  let previews = [...($draft.photoPreviews || [])]
  let files    = [...($draft.photos || [])]
  let loading  = false
  let error    = ''

  function handleFileInput(e) {
    const picked = Array.from(e.target.files || [])
    picked.forEach(file => {
      files = [...files, file]
      previews = [...previews, URL.createObjectURL(file)]
    })
    draft.update(d => ({ ...d, photos: files, photoPreviews: previews }))
    e.target.value = ''
  }

  function removePhoto(i) {
    URL.revokeObjectURL(previews[i])
    previews = previews.filter((_, idx) => idx !== i)
    files    = files.filter((_, idx) => idx !== i)
    draft.update(d => ({ ...d, photos: files, photoPreviews: previews }))
  }

  async function submit() {
    loading = true; error = ''
    const d = $draft
    const user = $authStore.user
    if (!user) { error = 'Not logged in'; loading = false; return }

    try {
      // 1. Insert post
      const { data: post, error: pe } = await supabase
        .from('posts')
        .insert({
          donor_id:   user.id,
          address:    d.address,
          lat:        d.lat,
          lng:        d.lng,
          expires_at: d.expires_at || null,
        })
        .select()
        .single()
      if (pe) throw pe

      // 2. Insert post_items
      const itemPayload = d.items.map(it => ({
        post_id:  post.id,
        name:     it.name,
        quantity: Number(it.quantity),
        available: Number(it.quantity),
        is_veg:   it.is_veg,
      }))
      const { error: ie } = await supabase.from('post_items').insert(itemPayload)
      if (ie) throw ie

      // 3. Upload photos
      const photoPaths = []
      for (const file of files) {
        const path = `${user.id}/${post.id}/${Date.now()}-${file.name}`
        const { error: ue } = await supabase.storage
          .from('post-photos')
          .upload(path, file, { upsert: false })
        if (ue) throw ue
        photoPaths.push(path)
      }
      if (photoPaths.length > 0) {
        const { error: phE } = await supabase.from('post_photos').insert(
          photoPaths.map(p => ({ post_id: post.id, storage_path: p }))
        )
        if (phE) throw phE
      }

      resetDraft()
      onDone()
    } catch (e) {
      error = e?.message || 'Something went wrong'
    } finally {
      loading = false
    }
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

  <div class="step-bar">
    <div class="step-row done">
      <div class="step-line-col">
        <div class="step-dot"></div>
        <div class="step-connector"></div>
      </div>
      <span class="step-label">1. Add an address</span>
    </div>
    <div class="step-row done">
      <div class="step-line-col">
        <div class="step-dot"></div>
        <div class="step-connector"></div>
      </div>
      <span class="step-label">2. Enter details</span>
    </div>
    <div class="step-row active">
      <div class="step-line-col"><div class="step-dot"></div></div>
      <div style="flex:1">
        <span class="step-label">3. Add photos</span>
        <div style="margin-top:10px">
          {#if error}
            <div class="error-msg mt-8">{error}</div>
          {/if}
          <div class="photo-grid">
            {#each previews as url, i}
              <div class="photo-thumb">
                <img src={url} alt="Food photo preview {i+1}" />
                <button class="photo-remove" on:click={() => removePhoto(i)} aria-label="Remove photo">✕</button>
              </div>
            {/each}
            <label class="photo-add-btn" for="photo-input">
              <span class="plus">⊕</span>
              <span>Add photo</span>
            </label>
            <input
              id="photo-input"
              type="file"
              accept="image/*"
              multiple
              style="display:none"
              on:change={handleFileInput}
            />
          </div>
          <p class="text-muted mt-12" style="font-size:.8rem">
            Photos help NGOs identify the food quickly.
          </p>
        </div>
      </div>
    </div>
  </div>

  <div class="bottom-bar">
    <button id="step3-submit" class="btn btn-primary" on:click={submit} disabled={loading}>
      {loading ? 'Submitting…' : 'Submit post'}
    </button>
  </div>
</div>

<style>
.report-page { min-height: 100dvh; padding-bottom: 90px; }
</style>
