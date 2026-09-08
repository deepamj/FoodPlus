<script>
  import { authStore } from './lib/stores/auth.js'
  import Landing     from './routes/Landing.svelte'
  import Auth        from './routes/Auth.svelte'
  import Step1       from './routes/report/Step1Address.svelte'
  import Step2       from './routes/report/Step2Details.svelte'
  import Step3       from './routes/report/Step3Photos.svelte'
  import Browse      from './routes/collect/Browse.svelte'
  import Claim       from './routes/collect/Claim.svelte'
  import Dashboard   from './routes/donor/Dashboard.svelte'

  // ---------------------------------------------------------------------------
  // Router — simple string-based view state (no lib needed for this SPA)
  // ---------------------------------------------------------------------------
  //  'landing' | 'auth' | 'report1' | 'report2' | 'report3'
  //  | 'collect-browse' | 'collect-claim' | 'donor-dash'
  // ---------------------------------------------------------------------------
  let view    = 'landing'
  let intent  = null   // 'report' | 'collect' — captured before auth
  let claimPost = null // the post selected in Browse

  // After auth, redirect to the right view
  function afterAuth() {
    const profile = $authStore.profile
    if (!profile) { view = 'landing'; return }
    if (intent === 'report' || profile.user_type === 'donor') {
      view = 'donor-dash'
    } else {
      view = 'collect-browse'
    }
    intent = null
  }

  function goReport() {
    if (!$authStore.user) { intent = 'report'; view = 'auth'; return }
    view = 'report1'
  }

  function goCollect() {
    if (!$authStore.user) { intent = 'collect'; view = 'auth'; return }
    view = 'collect-browse'
  }

  function onLogout() { view = 'landing' }
</script>

<div id="app">
  {#if $authStore.loading}
    <div class="spinner" style="margin-top:40vh"></div>

  {:else if view === 'landing'}
    <Landing goReport={goReport} goCollect={goCollect} />

  {:else if view === 'auth'}
    <Auth onAuth={afterAuth} />

  {:else if view === 'report1'}
    <Step1
      onNext={() => view = 'report2'}
      onBack={() => view = 'donor-dash'}
    />

  {:else if view === 'report2'}
    <Step2
      onNext={() => view = 'report3'}
      onBack={() => view = 'report1'}
    />

  {:else if view === 'report3'}
    <Step3
      onDone={() => view = 'donor-dash'}
      onBack={() => view = 'report2'}
    />

  {:else if view === 'donor-dash'}
    <Dashboard
      onNewPost={() => view = 'report1'}
      onLogout={onLogout}
    />

  {:else if view === 'collect-browse'}
    <Browse
      onSelect={(post) => { claimPost = post; view = 'collect-claim' }}
      onBack={() => view = 'landing'}
    />

  {:else if view === 'collect-claim'}
    <Claim
      post={claimPost}
      onDone={() => view = 'collect-browse'}
      onBack={() => view = 'collect-browse'}
    />
  {/if}
</div>
