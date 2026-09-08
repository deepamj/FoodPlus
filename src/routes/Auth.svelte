<script>
  import { supabase } from '../lib/supabase.js'
  import Wordmark from '../lib/components/Wordmark.svelte'

  export let onAuth = () => {}   // called after successful auth

  let tab = 'login'   // 'login' | 'signup'
  let email = '', password = '', name = '', orgName = '', userType = 'donor'
  let loading = false, error = ''

  async function handleLogin() {
    loading = true; error = ''
    const { error: e } = await supabase.auth.signInWithPassword({ email, password })
    loading = false
    if (e) { error = e.message; return }
    onAuth()
  }

  async function handleSignup() {
    loading = true; error = ''
    if (!name.trim()) { error = 'Please enter your name.'; loading = false; return }
    const { data, error: e } = await supabase.auth.signUp({ email, password })
    if (e) { error = e.message; loading = false; return }
    // Create profile row
    const { error: pe } = await supabase.from('profiles').insert({
      id: data.user.id,
      name: name.trim(),
      org_name: orgName.trim() || null,
      user_type: userType
    })
    loading = false
    if (pe) { error = pe.message; return }
    onAuth()
  }
</script>

<div class="auth-page">
  <Wordmark />

  <div class="auth-tabs">
    <button class="auth-tab" class:active={tab==='login'} on:click={() => tab='login'}>Log in</button>
    <button class="auth-tab" class:active={tab==='signup'} on:click={() => tab='signup'}>Sign up</button>
  </div>

  {#if error}
    <div class="error-msg mt-8">{error}</div>
  {/if}

  {#if tab === 'login'}
    <form class="auth-form" on:submit|preventDefault={handleLogin}>
      <label for="login-email">Email</label>
      <input id="login-email" class="input" type="email" placeholder="you@example.com" bind:value={email} required />
      <label for="login-pass">Password</label>
      <input id="login-pass" class="input" type="password" placeholder="••••••••" bind:value={password} required />
      <button type="submit" class="btn btn-primary mt-8" disabled={loading}>
        {loading ? 'Logging in…' : 'Log in'}
      </button>
    </form>
    <p class="text-center text-muted mt-16" style="font-size:.85rem">
      No account? <button class="btn btn-ghost btn-sm" style="display:inline;padding:2px 8px" on:click={() => tab='signup'}>Sign up</button>
    </p>

  {:else}
    <form class="auth-form" on:submit|preventDefault={handleSignup}>
      <label for="su-name">Your name</label>
      <input id="su-name" class="input" placeholder="Full name" bind:value={name} required />

      <label for="su-org">Organisation / venue name</label>
      <input id="su-org" class="input" placeholder="e.g. Canteen Block A (optional)" bind:value={orgName} />

      <label for="su-email">Email</label>
      <input id="su-email" class="input" type="email" placeholder="you@example.com" bind:value={email} required />

      <label for="su-pass">Password</label>
      <input id="su-pass" class="input" type="password" placeholder="Min. 6 characters" bind:value={password} required minlength="6" />

      <fieldset style="border:none;padding:0;margin:0">
        <legend style="font-size:.82rem;font-weight:600;color:var(--text-muted);margin-bottom:8px">I am a…</legend>
        <div class="role-select">
        <div class="role-card" class:selected={userType==='donor'} on:click={() => userType='donor'} role="radio" aria-checked={userType==='donor'} tabindex="0" on:keypress={e=>e.key==='Enter'&&(userType='donor')}>
          <div class="role-card-icon">
            <!-- Tray / food-service icon -->
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
              <path d="M3 11h18"/>
              <path d="M12 3C7 3 3 7 3 11h18c0-4-4-8-9-8z"/>
              <path d="M2 14h20"/>
              <path d="M5 14v3a1 1 0 001 1h12a1 1 0 001-1v-3"/>
            </svg>
          </div>
          <div class="role-card-label">Donor</div>
          <div class="role-card-sub">Canteen, restaurant, or volunteer</div>
        </div>
        <div class="role-card" class:selected={userType==='ngo'} on:click={() => userType='ngo'} role="radio" aria-checked={userType==='ngo'} tabindex="0" on:keypress={e=>e.key==='Enter'&&(userType='ngo')}>
          <div class="role-card-icon">
            <!-- Handshake / community icon -->
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
              <path d="M9 11l3 3L22 4"/>
              <path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11"/>
            </svg>
          </div>
          <div class="role-card-label">NGO / Collector</div>
          <div class="role-card-sub">Charity or food bank</div>
        </div>
        </div>
      </fieldset>

      <button type="submit" class="btn btn-primary mt-8" disabled={loading}>
        {loading ? 'Creating account…' : 'Create account'}
      </button>
    </form>
  {/if}
</div>
